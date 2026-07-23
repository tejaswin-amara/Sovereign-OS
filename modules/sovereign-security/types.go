package main

import "time"

type SecuritySeverity string

const (
	SeverityLow      SecuritySeverity = "LOW"
	SeverityMedium   SecuritySeverity = "MEDIUM"
	SeverityHigh     SecuritySeverity = "HIGH"
	SeverityCritical SecuritySeverity = "CRITICAL"
)

type SecurityFinding struct {
	RuleID      string           `json:"rule_id"`
	FilePath    string           `json:"file_path"`
	Line        int              `json:"line"`
	Severity    SecuritySeverity `json:"severity"`
	Description string           `json:"description"`
	Snippet     string           `json:"snippet"`
}

type ScanReport struct {
	ScanID     string            `json:"scan_id"`
	Timestamp  time.Time         `json:"timestamp"`
	FilesScanned int             `json:"files_scanned"`
	Findings   []SecurityFinding `json:"findings"`
	Status     string            `json:"status"`
}
