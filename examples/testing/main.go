package main

import (
	"fmt"

	"golang.org/x/text/language"
)

func main() {
	tags, _, err := language.ParseAcceptLanguage("en-US,en;q=0.9,fr;q=0.8")
	if err != nil {
		panic(err)
	}

	fmt.Println("Parsed language tags:")
	for _, tag := range tags {
		fmt.Println("-", tag)
	}
}