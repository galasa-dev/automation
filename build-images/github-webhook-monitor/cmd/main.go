/*
 * Copyright contributors to the Galasa Project
 */
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
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

const latestIdPath = "/latestId"

var client = http.Client{

	Timeout: time.Second * 30,
}

func main() {
	/**
	This poll logic needs to locate all the webhooks in an org, then search all deliveries from the webhooks cross referencing a mounted record of webhook

	Arguments required:
		String Github Org - which org we are watching
		String Github Token - access token
		String Hook ID - mostly to save api calls
		String Config Map - yaml file for mapping webhooks to event listeners

	Poll frequency can be controlled from K8s Cron job of how often this is run. Also allows for simple manual trigger
	*/
	parseArgsAndConfigs()

	var deliveries []jsontypes.Delivery
	var eventQueue []string

	page := 1
	resp := GithubGet(fmt.Sprintf("https://api.github.com/orgs/%s/hooks/%s/deliveries?per_page=50", *orgName, *hookId), nil)
	link := resp.Header["Link"][0]
	segments := strings.Split(strings.TrimSpace(link), ";")

	// If latestId not set, we assume this is startup and to only act on anything new past this point. Mark the newest as latestId event though no action.
	if latestDeliveryId == "" {
		f, err := os.Create(latestIdPath)
		if err != nil {
			log.Printf("Failed to create Id file", err)
		}
		parseDeliveries(resp.Body, &deliveries)
		f.WriteString(strconv.Itoa(deliveries[0].Id))
		os.Exit(0)
	}

	upToDate := false
	// Look at the last 250 Events max
	for page < 5 {
		nextPage := strings.Trim(segments[0], "<>")

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

		resp = GithubGet(nextPage, nil)
		page++
	}

	if len(eventQueue) == 0 {
		log.Printf("Nothing to do")
		return
	}

	for i, j := 0, len(eventQueue)-1; i < j; i, j = i+1, j-1 {
		eventQueue[i], eventQueue[j] = eventQueue[j], eventQueue[i]
	}

	log.Printf("%v found\n %v", len(eventQueue), eventQueue)

	// Now need to submit all events to event listener
	for _, id := range eventQueue {
		log.Printf("Inspecting event: %s", id)
		hookRequest, err := buildHookRequest(id)
		if err != nil {
			log.Fatal(err)
		}
		if hookRequest == nil {
			// Update the bookmark to the last checked, even if no actin=on
			updateBookmark(id)
			continue
		}
		resp, err := client.Do(hookRequest)
		if err != nil {
			log.Printf("WARNING: failed to send webhook to event listener: %s\n", hookRequest.URL)
		} else {
			log.Printf("URL: %s - Response: %v", resp.Request.URL, resp.StatusCode)
		}

		// We update the bookmark without ensuring 202 to prevent a backlog of missed events.
		updateBookmark(id)
	}

}

// Does a look up with the Github API to find the hook requests and payloads. Then creates new http request from output
func buildHookRequest(id string) (*http.Request, error) {
	var request jsontypes.WebhookRequest
	resp := GithubGet(fmt.Sprintf("https://api.github.com/orgs/%s/hooks/%s/deliveries/%s", *orgName, *hookId, id), nil)
	b, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatal("Failed retrieving webhook request body.", err)
	}

	json.Unmarshal(b, &request)

	if eventType, ok := triggerMap.Events[request.Event]; ok {
		url := eventType.EventListener
		payload, _ := json.Marshal(request.Request.Payload)
		webookRequest, err := http.NewRequest("POST", url, bytes.NewReader(payload))
		if err != nil {
			return nil, err
		}

		// Add headers
		for k, v := range request.Request.Headers {
			webookRequest.Header.Add(k, v)
		}
		return webookRequest, nil
	} else {
		log.Printf("No action required for type: %s\n", request.Event)
	}

	return nil, nil
}

// Extracts Delivery Json from body.
func parseDeliveries(body io.ReadCloser, v interface{}) {
	b, err := ioutil.ReadAll(body)
	if err != nil {
		log.Fatal("Failed to parse response body into interface", err)
	}
	err = json.Unmarshal(b, &v)
	if err != nil {
		log.Fatal("Failed to unmarshal delivery response", err)
	}
}

// Does an authenticated request to github API.
func GithubGet(url string, headers map[string]string) *http.Response {
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
	b, err := ioutil.ReadFile(*triggerMapPath)
	if err != nil {
		log.Fatal("Failed to open trigger mappings\n", err)
	}
	yaml.Unmarshal(b, &triggerMap)

	b, err = ioutil.ReadFile(latestIdPath)
	if err != nil {
		log.Println("Failed to find lastestId file")
		return
	}
	latestDeliveryId = string(b)
	log.Printf("LatestID is %s", latestDeliveryId)
}
