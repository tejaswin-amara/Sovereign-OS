package types

import "time"

// SovereignConfig represents the root sovereign.config.json configuration structure.
type SovereignConfig struct {
	Version      string                  `json:"version"`
	Environment  string                  `json:"environment"`
	MutexName    string                  `json:"mutex_name"`
	Telemetry    TelemetryConfig         `json:"telemetry"`
	Modules      map[string]ModuleConfig `json:"modules"`
	Skills       map[string]SkillConfig  `json:"skills"`
	AuditState   AuditStateConfig        `json:"audit_state"`
}

type TelemetryConfig struct {
	Enabled   bool   `json:"enabled"`
	LogPath   string `json:"log_path"`
	MaxAgeDays int   `json:"max_age_days"`
}

type ModuleConfig struct {
	Name        string `json:"name"`
	Category    string `json:"category"`
	Path        string `json:"path"`
	GoModule    string `json:"go_module,omitempty"`
	NpmPackage  string `json:"npm_package,omitempty"`
	Description string `json:"description"`
}

type SkillConfig struct {
	Name        string   `json:"name"`
	Category    string   `json:"category"`
	Path        string   `json:"path"`
	Description string   `json:"description"`
	Assets      []string `json:"assets"`
}

type AuditStateConfig struct {
	CertifiedState string    `json:"certified_state"`
	LastAudited    time.Time `json:"last_audited"`
	Signer         string    `json:"signer"`
}

// SystemStatus holds runtime verification state.
type SystemStatus struct {
	MutexAcquired bool      `json:"mutex_acquired"`
	LatencyMs     int64     `json:"latency_ms"`
	SkillCount    int       `json:"skill_count"`
	ModuleCount   int       `json:"module_count"`
	Timestamp     time.Time `json:"timestamp"`
}
