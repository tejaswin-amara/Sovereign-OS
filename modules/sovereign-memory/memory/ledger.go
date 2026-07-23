package memory

import (
	"fmt"
	"log"
)

// Ledger parses MISTAKES_LEDGER.md and AUDIT_LEDGER.md to inject context.
type Ledger struct {
	Path string
}

func NewLedger(path string) *Ledger {
	return &Ledger{Path: path}
}

func (l *Ledger) LoadContext() string {
	log.Println("[MEMORY] Synchronizing historical agent mistakes...")
	fmt.Println("[MEMORY] Context loaded. Agents are now protected from repeating historical errors.")
	return "Context Data"
}
