/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	jsontypes "github.com/galasa-dev/automation/build-images/github-webhook-monitor/pkg/jsonTypes"
	"github.com/galasa-dev/automation/build-images/github-webhook-monitor/pkg/mapper"
	"gopkg.in/yaml.v2"
)

var token string
var orgName *string
var triggerMapPath *string
var triggerMap mapper.Config
var hookId *string

var latestDeliveryId string

const (
	latestIdPath                            = "/mnt/latestId/latestId.txt"
	SLEEP_TIME_SECONDS_BETWEEN_GITHUB_POLLS = 120
)

var client = http.Client{
	Timeout: time.Second * 30,
}

/*
*
This poll logic needs to is given a webhook id, then search all deliveries from the webhook cross referencing a mounted mapper config

Arguments required:

	String Github Org - which org we are watching
	String Github Token - access token
	String Hook ID - mostly to save api calls
	String Config Map - yaml file for mapping webhooks to event listeners

Poll frequency can be controlled from K8s Cron job of how often this is run. Also allows for simple manual trigger
*/
func main() {
	var err error

	for {
		err = parseArgsAndConfigs()
		if err == nil {
			err = getAndSubmitEvents()
			if err == nil {
				// wait for more events to arrive at github... then check again.
				log.Printf("main - Going to sleep.")
				time.Sleep(SLEEP_TIME_SECONDS_BETWEEN_GITHUB_POLLS * time.Second)
				log.Printf("main - Just woke up.")
			} else {
				log.Printf("main FAIL - Error when getting and submitting events: %v", err)
				break
			}

		} else {
			log.Printf("main FAIL - Error when parsing args and configs: %v", err)
			break
		}

	}

	// If there has been an error, exit with an exit code of 1.
	var exitCode = 0
	if err != nil {
		exitCode = 1
	}

	os.Exit(exitCode)
}

func getAndSubmitEvents() error {
	var err error
	var orderedEventList []string

	log.Println("getAndSubmitEvents - Getting events....")

	orderedEventList, err = getEventList()

	log.Printf("getAndSubmitEvents - ordered event list: %v", orderedEventList)
	if err == nil {
		err = submitEvents(orderedEventList)
	}

	return err
}

func getEventList() ([]string, error) {
	var deliveries []jsontypes.Delivery
	var eventQueue []string
	var err error

	page := 1
	resp := githubGet(fmt.Sprintf("https://api.github.com/orgs/%s/hooks/%s/deliveries?per_page=50", *orgName, *hookId), nil)

	// If latestId not set, we assume this is startup and to only act on anything new past this point. Mark the newest as latestId event though no action.
	if latestDeliveryId == "" {
		log.Println("getEventList - LatestDeliveryId is empty")
		f, err := os.Create(latestIdPath)
		if err != nil {
			log.Printf("getEventList - Failed to create LatestDeliveryId file: %v", err)
		}
		log.Println("getEventList - LatestDeliveryId file has been created")
		parseDeliveries(resp.Body, &deliveries)
		f.WriteString(strconv.Itoa(deliveries[0].Id))
	} else {
		log.Printf("getEventList - LatestDeliveryId is %v", latestDeliveryId)
		upToDate := false
		// Look at the last 250 Events max
		for page < 5 {

			parseDeliveries(resp.Body, &deliveries)

			// Loop through current page entries
			for _, val := range deliveries {
				id := fmt.Sprintf("%v", val.Id)
				if id == latestDeliveryId {
					upToDate = true
					break
				} else {
					log.Printf("getEventList - appending event %s to event list...", id)
					eventQueue = append(eventQueue, id)
				}
			}
			if upToDate {
				break
			}

			// The Link header will only be present if there were more than 50 deliveries in the list so more than one page
			link := resp.Header["Link"]
			if len(link) == 0 {
				break
			}

			segments := strings.Split(strings.TrimSpace(link[0]), ";")
			nextPage := strings.Trim(segments[0], "<>")

			resp = githubGet(nextPage, nil)
			page++
		}

		if len(eventQueue) == 0 {
			log.Printf("getEventList - No events to submit")
			return eventQueue, err
		}

		for i, j := 0, len(eventQueue)-1; i < j; i, j = i+1, j-1 {
			eventQueue[i], eventQueue[j] = eventQueue[j], eventQueue[i]
		}
	}

	return eventQueue, err
}

func submitEvents(events []string) error {
	var err error
	log.Printf("submitEvents - %v events found\n %v", len(events), events)

	// Now need to submit all events to event listener
	for _, id := range events {
		log.Printf("submitEvents - Inspecting event: %s", id)
		var hookRequest *http.Request
		hookRequest, err = buildHookRequest(id)
		if err != nil {
			log.Printf("submitEvents - Error when building hook request: %v", err)
			break
		}

		if hookRequest != nil {
			var resp *http.Response
			resp, err = client.Do(hookRequest)
			if err != nil {
				log.Printf("submitEvents - WARNING: failed to send webhook to event listener: %s\n", hookRequest.URL)
				break
			} else {
				log.Printf("submitEvents - URL: %s - Response: %v", resp.Request.URL, resp.StatusCode)
			}
		}

		// We update the bookmark without ensuring 202 to prevent a backlog of missed events.
		updateBookmark(id)
	}

	return err
}

// Does a look up with the Github API to find the hook requests and payloads. Then creates new http request from output
func buildHookRequest(id string) (*http.Request, error) {
	var request jsontypes.WebhookRequest
	resp := githubGet(fmt.Sprintf("https://api.github.com/orgs/%s/hooks/%s/deliveries/%s", *orgName, *hookId, id), nil)
	b, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("buildHookRequest - Failed retrieving webhook request body. %v\n", err)
	} else {

		err = json.Unmarshal(b, &request)
		if err == nil {

			if eventType, ok := triggerMap.Events[request.Event]; ok {
				url := eventType.EventListener
				payload, _ := json.Marshal(request.Request.Payload)
				webhookRequest, err := http.NewRequest("POST", url, bytes.NewReader(payload))
				if err != nil {
					return nil, err
				}

				// Add headers
				for k, v := range request.Request.Headers {
					webhookRequest.Header.Add(k, v)
				}

				return webhookRequest, nil
			} else {
				log.Printf("buildHookRequest - No action required for type: %s\n", request.Event)
			}
		}
	}

	return nil, err
}

// Extracts Delivery Json from body.
func parseDeliveries(body io.ReadCloser, v interface{}) {
	b, err := io.ReadAll(body)
	if err != nil {
		log.Fatal("parseDeliveries - Failed to parse response body into interface", err)
	}

	err = json.Unmarshal(b, &v)
	if err != nil {
		log.Fatalf("parseDeliveries - Failed to unmarshal delivery response. Error: %v", err)
	}
}

// Does an authenticated request to github API.
func githubGet(url string, headers map[string]string) *http.Response {
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Add("Accept", "application/vnd.github+json")
	req.Header.Add("Authorization", fmt.Sprintf("Bearer %s", token))

	for key, value := range headers {
		req.Header.Add(key, value)
	}

	resp, err := client.Do(req)
	if err != nil {
		log.Fatal(fmt.Sprintf("githubGet - Failed to execute GET request to %s", url), err)
	}

	// Do a basic OK check
	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(resp.Body)
		log.Printf("githubGet - HTTP resp body: %s", string(b))
		log.Fatalf(fmt.Sprintf("githubGet - HTTP response status: %s from %s", resp.Status, url))
	}

	return resp
}

// Write to file in truncate mode to record last actioned ID.
func updateBookmark(id string) {
	log.Printf("updateBookmark - updating event id to %s", id)
	f, err := os.OpenFile(latestIdPath, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0755)
	if err != nil {
		log.Fatalf("updateBookmark - Error opening file: %v", err)
	}

	f.WriteString(id)
	f.Close()
}

// Parse all runtime arguments and environment variables.
func parseArgsAndConfigs() error {
	log.Printf("parseArgsAndConfigs - command args - %v\n", os.Args)

	// Set with K8s secret mount
	token = os.Getenv("GITHUBTOKEN")

	// E.g. -org=galasa-dev
	if flag.Lookup("org") == nil {
		orgName = flag.String("org", "", "Name of github Organisation we are monitoring")
	}
	// E.g. -trigger-map=/home/user/map
	if flag.Lookup("trigger-map") == nil {
		triggerMapPath = flag.String("trigger-map", "", "Yaml config map for routing triggers to event listeners")
	}
	// E.g. -hook=000000
	if flag.Lookup("hook") == nil {
		hookId = flag.String("hook", "", "Id for Webhook to watch")
	}

	flag.Parse()
	if *hookId == "" {
		log.Fatal("parseArgsAndConfigs - An webhook id must be passed. Please use the -hook flag.")
	}
	if *orgName == "" {
		log.Fatal("parseArgsAndConfigs - An github organisation must be passed. Please use the -org flag.")
	}

	//Read trigger configs
	b, err := os.ReadFile(*triggerMapPath)
	if err != nil {
		log.Fatal("parseArgsAndConfigs - Failed to open trigger mappings\n", err)
	}

	err = yaml.Unmarshal(b, &triggerMap)
	if err == nil {
		b, err = os.ReadFile(latestIdPath)
		if err != nil {
			log.Printf("parseArgsAndConfigs - Failed to find latestId file. Error: %v", err.Error())
			return nil
		}
		latestDeliveryId = string(b)
		log.Printf("parseArgsAndConfigs - LatestID recovered from bookmark file is %s", latestDeliveryId)
	}

	return err
}
