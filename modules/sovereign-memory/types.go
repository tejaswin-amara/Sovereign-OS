package main

import "time"

type MemoryEntry struct {
	ID        string    `json:"id"`
	Key       string    `json:"key"`
	Value     string    `json:"value"`
	Category  string    `json:"category"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type MemoryStore struct {
	Namespace string                 `json:"namespace"`
	Entries   map[string]MemoryEntry `json:"entries"`
}
