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

const latestIdPath = "/mnt/latestId"

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
	log.Println("Main - entered......")
	parseArgsAndConfigs()

	//Returns a list with the oldest relevant event first
	orderedEventList := getEventList()

	// Submits the events to any relevant webhook defined
	submitEvents(orderedEventList)
}

func getEventList() []string {
	var deliveries []jsontypes.Delivery
	var eventQueue []string

	page := 1
	resp := githubGet(fmt.Sprintf("https://api.github.com/orgs/%s/hooks/%s/deliveries?per_page=50", *orgName, *hookId), nil)

	// If latestId not set, we assume this is startup and to only act on anything new past this point. Mark the newest as latestId event though no action.
	if latestDeliveryId == "" {
		f, err := os.Create(latestIdPath)
		if err != nil {
			log.Printf("Failed to create Id file: %s", err)
		}
		parseDeliveries(resp.Body, &deliveries)
		f.WriteString(strconv.Itoa(deliveries[0].Id))
		os.Exit(0)
	}

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
		log.Printf("Nothing to do")
		return eventQueue
	}

	for i, j := 0, len(eventQueue)-1; i < j; i, j = i+1, j-1 {
		eventQueue[i], eventQueue[j] = eventQueue[j], eventQueue[i]
	}

	return eventQueue
}

func submitEvents(events []string) {
	log.Printf("%v found\n %v", len(events), events)

	// Now need to submit all events to event listener
	for _, id := range events {
		log.Printf("Inspecting event: %s", id)
		hookRequest, err := buildHookRequest(id)
		if err != nil {
			log.Fatal(err)
		}

		if hookRequest != nil {
			resp, err := client.Do(hookRequest)
			if err != nil {
				log.Printf("WARNING: failed to send webhook to event listener: %s\n", hookRequest.URL)
			} else {
				log.Printf("URL: %s - Response: %v", resp.Request.URL, resp.StatusCode)
			}
		}

		// We update the bookmark without ensuring 202 to prevent a backlog of missed events.
		updateBookmark(id)
	}
}

// Does a look up with the Github API to find the hook requests and payloads. Then creates new http request from output
func buildHookRequest(id string) (*http.Request, error) {
	var request jsontypes.WebhookRequest
	resp := githubGet(fmt.Sprintf("https://api.github.com/orgs/%s/hooks/%s/deliveries/%s", *orgName, *hookId, id), nil)
	b, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatal("Failed retrieving webhook request body.", err)
	}

	json.Unmarshal(b, &request)

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
		log.Printf("No action required for type: %s\n", request.Event)
	}

	return nil, nil
}

// Extracts Delivery Json from body.
func parseDeliveries(body io.ReadCloser, v interface{}) {
	b, err := io.ReadAll(body)
	if err != nil {
		log.Fatal("Failed to parse response body into interface", err)
	}
	err = json.Unmarshal(b, &v)
	if err != nil {
		log.Fatal("Failed to unmarshal delivery response", err)
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
		log.Fatal(fmt.Sprintf("Failed to execute GET request to %s", url), err)
	}

	// Do a basic OK check
	if resp.StatusCode != http.StatusOK {
		log.Fatal(fmt.Sprintf("Status: %s from %s", resp.Status, url))
	}

	return resp
}

// Write to file in truncate mode to record last actioned ID.
func updateBookmark(id string) {
	f, err := os.OpenFile(latestIdPath, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0755)
	if err != nil {
		log.Fatal(err)
	}
	f.WriteString(id)
	f.Close()
}

// Parse all runtime arguments and environment variables.
func parseArgsAndConfigs() {
	// Set with K8s secret mount
	token = os.Getenv("GITHUBTOKEN")

	// E.g. -org=galasa-dev
	orgName = flag.String("org", "", "Name of github Organisation we are monitoring")
	// E.g. -trigger-map=/home/user/map
	triggerMapPath = flag.String("trigger-map", "", "Yaml config map for routing triggers to event listeners")
	// E.g. -hook=000000
	hookId = flag.String("hook", "", "Id for Webhook to watch")

	flag.Parse()
	if *hookId == "" {
		log.Fatal("An webhook id must be passed. Please use the -hook flag.")
	}
	if *orgName == "" {
		log.Fatal("An github organisation must be passed. Please use the -org flag.")
	}

	//Read trigger configs
	b, err := os.ReadFile(*triggerMapPath)
	if err != nil {
		log.Fatal("Failed to open trigger mappings\n", err)
	}
	yaml.Unmarshal(b, &triggerMap)

	b, err = os.ReadFile(latestIdPath)
	if err != nil {
		log.Println("Failed to find latestId file")
		return
	}
	latestDeliveryId = string(b)
	log.Printf("LatestID is %s", latestDeliveryId)
}
