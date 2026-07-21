# Sovereign Asset Registry (V16)

> **Purpose:** This registry lists approved external repositories that agents can dynamically research and pull in using `agent-reach` when a task explicitly demands them. In accordance with the Ponytail doctrine, DO NOT install these globally or permanently unless the core architecture requires it.

## CI & Automation
- **GitHub Actions (Checkout):** `https://github.com/actions/checkout`
- **GoReleaser (Cross-compilation):** `https://github.com/goreleaser/goreleaser`

## Security & Analysis
- **Trivy (Vulnerability Scanner):** `https://github.com/aquasecurity/trivy`
- **GoSec (Go Security Checker):** `https://github.com/securego/gosec`
- **GolangCI-Lint (Linter Aggregator):** `https://github.com/golangci/golangci-lint`

## CLI & Configuration
- **Cobra (CLI Application Framework):** `https://github.com/spf13/cobra`
- **Viper (Configuration Management):** `https://github.com/spf13/viper`

## Observability
- **Zap (Blazing fast, structured logging):** `https://github.com/uber-go/zap`
- **Zerolog (Zero Allocation JSON Logger):** `https://github.com/rs/zerolog`

## Agent Orchestration
- **LangChain-Go:** `https://github.com/tmc/langchaingo`
- **Open Agent Framework (Go):** `https://github.com/openai/open-agent-framework-go`

## UI & Design Systems
- **Shadcn-UI (Accessible Components):** `https://github.com/shadcn-ui/ui`
- **TailwindCSS (Utility-first CSS):** `https://github.com/tailwindlabs/tailwindcss`

## Usage Instructions for Agents
1. Evaluate the user's request. Does it introduce a concrete, undeniable need for one of these tools?
2. If yes, use `agent-reach` to research the tool's documentation on GitHub.
3. Integrate the tool into the specific component where it is needed, either via a package manager (`go get`, `npm install`) or as a GitHub Action step.
4. **Never** add these as Git submodules in the Sovereign root unless it fundamentally modifies the Master Controller.
