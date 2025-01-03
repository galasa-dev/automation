/*
 * Copyright contributors to the Galasa project
 *
 * SPDX-License-Identifier: EPL-2.0
 */
package mapper

type Config struct {
	Events map[string]Event `yaml:"events"`
}

type Event struct {
	EventListener []string `yaml:"eventListener"`
}
