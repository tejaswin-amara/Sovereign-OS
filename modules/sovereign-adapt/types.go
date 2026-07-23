package main

import "time"

type AdaptStrategy string

const (
	StrategyMinimal AdaptStrategy = "MINIMAL"
	StrategyFull    AdaptStrategy = "FULL"
	StrategyStrict  AdaptStrategy = "STRICT"
)

type AdaptationPolicy struct {
	Strategy      AdaptStrategy `json:"strategy"`
	AutoRemediate bool          `json:"auto_remediate"`
	MaxRetries    int           `json:"max_retries"`
	TimeoutSec    int           `json:"timeout_sec"`
}

type AdaptationLog struct {
	ID        string    `json:"id"`
	Action    string    `json:"action"`
	Outcome   string    `json:"outcome"`
	Timestamp time.Time `json:"timestamp"`
}
