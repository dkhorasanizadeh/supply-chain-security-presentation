package main

import (
	"fmt"
	"log"
	"net/http"
	"strings"

	"golang.org/x/net/html"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_, err := html.Parse(strings.NewReader("<title>Supply-chain demo</title>"))
		if err != nil {
			http.Error(w, "parse failed", http.StatusInternalServerError)
			return
		}
		fmt.Fprintln(w, "Supply-chain demo app; html-parser=ok")
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
