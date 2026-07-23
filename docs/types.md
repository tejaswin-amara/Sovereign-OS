# Sovereign-OS V17 — Complete Types Reference

This document provides a single reference for type definitions across TypeScript, Go, and JSON Schemas in Sovereign-OS.

---

## 1. TypeScript Types (`modules/sovereign-ui/src/types/index.ts`)

```typescript
export type ModuleCategory = 'cli' | 'ui' | 'mcp' | 'pipeline' | 'security' | 'memory' | 'adapt';
export type SkillCategory = 'research' | 'philosophy' | 'automation';
export type HealthStatus = 'healthy' | 'degraded' | 'offline' | 'pristine';

export interface SovereignModule {
  id: string;
  name: string;
  category: ModuleCategory;
  version: string;
  path: string;
  status: HealthStatus;
  goModule?: string;
  npmPackage?: string;
  lastVerified: string;
}

export interface SovereignSkill {
  name: string;
  category: SkillCategory;
  path: string;
  description: string;
  dynamicAssets: string[];
  enabled: boolean;
}

export interface MutexState {
  acquired: boolean;
  name: string;
  pid?: number;
  acquiredAt?: string;
}

export interface TelemetryMetric {
  executionTimeMs: number;
  dynamicSkillCount: number;
  dynamicModuleCount: number;
  timestamp: string;
}

export interface SystemAuditLedger {
  version: string;
  certifiedState: string;
  lastUpdated: string;
  totalModules: number;
  totalSkills: number;
  auditSignatures: string[];
}

export interface SovereignSystemStatus {
  system: string;
  version: string;
  status: HealthStatus;
  mutex: MutexState;
  telemetry: TelemetryMetric;
  modules: SovereignModule[];
  skills: SovereignSkill[];
  ledger: SystemAuditLedger;
}
```

---

## 2. Go Types (`modules/sovereign-cli/pkg/types/types.go`)

```go
package types

import "time"

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
	Enabled    bool   `json:"enabled"`
	LogPath    string `json:"log_path"`
	MaxAgeDays int    `json:"max_age_days"`
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

type SystemStatus struct {
	MutexAcquired bool      `json:"mutex_acquired"`
	LatencyMs     int64     `json:"latency_ms"`
	SkillCount    int       `json:"skill_count"`
	ModuleCount   int       `json:"module_count"`
	Timestamp     time.Time `json:"timestamp"`
}
```

---

## 3. Security & Memory Types (`modules/sovereign-security` & `modules/sovereign-memory`)

```go
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

type MemoryEntry struct {
	ID        string    `json:"id"`
	Key       string    `json:"key"`
	Value     string    `json:"value"`
	Category  string    `json:"category"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
```
