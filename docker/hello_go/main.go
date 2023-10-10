package main

import (
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		w.Write([]byte("hello world"))
	})
	err := http.ListenAndServe(":80", nil)
	if err != nil {
		panic(err)
	}
}
