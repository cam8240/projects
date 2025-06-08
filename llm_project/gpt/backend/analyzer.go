package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

type Request struct {
	Text string `json:"text"`
}

type Response struct {
	WordCount     int `json:"word_count"`
	CharacterCount int `json:"character_count"`
}

func analyzeHandler(w http.ResponseWriter, r *http.Request) {
	var req Request
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil || strings.TrimSpace(req.Text) == "" {
		http.Error(w, "Invalid input", http.StatusBadRequest)
		return
	}

	text := req.Text

	words := strings.Fields(text)

	resp := Response{
		WordCount:     len(words),
		CharacterCount: len(text),
	}
	fmt.Printf("Response: WordCount=%d, CharacterCount=%d\n", resp.WordCount, resp.CharacterCount)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func main() {
	http.HandleFunc("/analyze", analyzeHandler)
	fmt.Println("Go analyzer running on :6000")
	err := http.ListenAndServe(":6000", nil)
	if err != nil {
		fmt.Println("Error starting server:", err)
	}
}

