/*
 * Copyright contributors to the Galasa Project
 */
package mapper

type Config struct {
	Events map[string]Event `yaml:"events"`
}

type Event struct {
	EventListener string `yaml:"eventListener"`
}
