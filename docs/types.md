# Sovereign-OS Global Type Registry

This document serves as the authoritative source of truth for all cross-module data structures, configurations, and API contracts within the Sovereign-OS architecture.

---

## 1. Core Configuration (`sovereign.config.json`)

The primary configuration object governing the state and module initialization for Sovereign-OS.

```typescript
interface SovereignConfig {
  version: string; // e.g. "18.0.0-Rulebook"
  name: string;
  core_axioms: string[];
  description: string;
  paths: {
    skills_root: string;
    version_file: string;
    logs_dir: string;
    asset_registry: string;
  };
  commands: {
    system: string[];
    agent: string[];
    control: string[];
  };
  submodules: Record<string, {
    path: string;
    upstream: string;
    purpose: string;
  }>;
  governance: {
    skills_count: number;
    modules_count: number;
    lock_timeout_seconds: number;
    log_retention_days: number;
    log_max_size_mb: number;
  };
}
```

---

## 2. Agent Ledgers (`AUDIT_LEDGER.md` & `MISTAKES_LEDGER.md`)

When parsing ledgers programmatically or generating reports, the structure follows this markdown schema constraint:

```go
type AuditEntry struct {
    Timestamp   string `json:"timestamp"`
    Action      string `json:"action"`
    Module      string `json:"module"`
    Outcome     string `json:"outcome"`
    Ponytail    bool   `json:"ponytail_compliant"`
}

type MistakeEntry struct {
    Timestamp   string `json:"timestamp"`
    Error       string `json:"error"`
    Resolution  string `json:"resolution"`
    Agent       string `json:"agent"`
}
```

---

## 3. UI Dashboard Telemetry (`modules/sovereign-ui`)

The Next.js front-end relies on the following TypeScript definitions for rendering system metrics.

```typescript
export interface SystemMetric {
  id: string;
  label: string;
  value: number | string;
  status: 'healthy' | 'warning' | 'critical';
  lastUpdated: string;
}

export interface ArchitectureNode {
  name: string;
  type: 'core' | 'cli' | 'ui' | 'gatekeeper';
  dependencies: string[];
}
```

---

## 4. No-Mistakes Pipeline (`modules/no-mistakes`)

The `no-mistakes` daemon uses the following internal types to evaluate runs and enforce pipeline constraints before a code push is authorized.

```go
// Represents a single verification run against a branch
type PipelineRun struct {
    ID           string       `json:"id"`
    Branch       string       `json:"branch"`
    HeadSHA      string       `json:"head_sha"`
    Status       string       `json:"status"` // "running", "completed", "failed", "parked"
    Intent       string       `json:"intent"` // User's natural language goal
    Steps        []RunStep    `json:"steps"`
}

// Represents an individual step within a run
type RunStep struct {
    Name       string   `json:"name"`     // e.g., "lint", "test", "review"
    Status     string   `json:"status"`   // "pending", "completed", "failed", "skipped"
    DurationMS int64    `json:"duration_ms"`
    Findings   []string `json:"findings"`
}
```

---

*Note: Any changes to module interfaces or additions to the architecture must be recorded here in accordance with AGENTS.md Directive V18.*
