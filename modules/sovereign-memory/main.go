package main

import (
	"fmt"
	"log"
	"os"

	"github.com/kunchenguid/sovereign-memory/memory"
)

func main() {
	log.Println("[SOVEREIGN-MEMORY] Initializing Semantic Context Ledger...")

	// Verify Ledger files exist
	ledgers := []string{"../../MISTAKES_LEDGER.md", "../../AUDIT_LEDGER.md"}
	for _, path := range ledgers {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			log.Fatalf("FATAL: Ponytail ledger %s missing. Knowledge graph cannot initialize.", path)
		}
	}

	// Instantiate the core ledger logic
	ledger := memory.NewLedger("../../MISTAKES_LEDGER.md")
	contextData := ledger.LoadContext()

	fmt.Println("[SOVEREIGN-MEMORY] Boot Sequence Complete.")
	fmt.Printf("[SOVEREIGN-MEMORY] Live Context Active: %s\n", contextData)
}
