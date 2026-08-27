package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

type Item struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

var items = struct {
	mu sync.Mutex
	m map[string]Item
}{
	mu: sync.Mutex{},
	m: make(map[string]Item),
}

func writeJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	body, err := json.Marshal(data)
	if err != nil {
		http.Error(w, `{"error":"internal server error"}`, http.StatusInternalServerError)
		return
	}
	w.WriteHeader(statusCode)
	w.Write(body)
}

func itemHandler(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case "GET":
		items.mu.Lock()
		list := make([]Item, 0, len(items.m))
		for _, item := range items.m {
			list = append(list, item)
		}
		items.mu.Unlock()
		writeJSON(w, http.StatusOK, map[string][]Item{"items": list})

	case "POST":
		var newItem Item
		if err := json.NewDecoder(r.Body).Decode(&newItem); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "Invalid JSON"})
			return
		}
		if newItem.Name == "" {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "name is required"})
			return
		}
		items.mu.Lock()
		newItem.ID = fmt.Sprintf("item-%d", len(items.m)+1)
		items.m[newItem.ID] = newItem
		items.mu.Unlock()
		writeJSON(w, http.StatusCreated, newItem)

	case "DELETE":
		items.mu.Lock()
		items.m = make(map[string]Item)
		items.mu.Unlock()
		writeJSON(w, http.StatusOK, map[string]bool{"removed": true})

	default:
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "Method not allowed"})
	}
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "healthy"})
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/items", itemHandler)

	port := 8080
	log.Printf("Go HTTP server running at http://0.0.0.0:%d/", port)
	if err := http.ListenAndServe(fmt.Sprintf("0.0.0.0:%d", port), mux); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}