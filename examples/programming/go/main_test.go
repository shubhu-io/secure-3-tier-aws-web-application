package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
)

type Item struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

func writeJSON(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	body, _ := json.Marshal(data)
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

func newServer() *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		itemHandler(w, r)
	}))
}

func TestGetWelcome(t *testing.T) {
	srv := newServer()
	defer srv.Close()

	resp, err := http.Get(srv.URL + "/")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestGetHealth(t *testing.T) {
	srv := newServer()
	defer srv.Close()

	resp, err := http.Get(srv.URL + "/health")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestGetItemsEmpty(t *testing.T) {
	srv := newServer()
	defer srv.Close()

	resp, err := http.Get(srv.URL + "/items")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestPostItemValid(t *testing.T) {
	srv := newServer()
	defer srv.Close()

	resp, err := http.Post(srv.URL+"/items", "application/json", nil)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201, got %d", resp.StatusCode)
	}
}

func TestPostItemMissingName(t *testing.T) {
	srv := newServer()
	defer srv.Close()

	resp, err := http.Post(srv.URL+"/items", "application/json", nil)
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", resp.StatusCode)
	}
}

func TestDeleteItems(t *testing.T) {
	srv := newServer()
	defer srv.Close()

	// First create an item
	http.Post(srv.URL+"/items", "application/json", nil)

	// Now delete
	resp, err := http.MethodDelete(srv.URL+"/items")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
}

func TestCyclicImportCheck(t *testing.T) {
	// Just verify the package compiles
	_ = Item{}
}