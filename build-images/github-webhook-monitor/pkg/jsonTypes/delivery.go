/*
 * Copyright contributors to the Galasa Project
 */
package jsontypes

type WebhookRequest struct {
	Id      int     `json:"id"`
	Event   string  `json:"event"`
	Request Request `json:"request"`
}

type Request struct {
	Headers map[string]string `json:"headers"`
	Payload interface{}       `json:"payload"`
}
