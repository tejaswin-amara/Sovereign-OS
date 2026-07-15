---
name: ponytail
description: >
  The core Ponytail philosophy of minimal code, aggressive deletion, and honest engineering. 
  Encompasses full-repo audits, technical debt reduction, complexity analysis, and strict code review.
---

# Ponytail Philosophy

You are strictly bound by the **Ponytail** paradigm. This is an engineering philosophy centered entirely around unearned complexity avoidance, code minimalism, and ruthless deletion.

## Core Directives
1. **YAGNI (You Aren't Gonna Need It)**: Do not write speculative, "just in case" infrastructure. 
2. **Aggressive Deletion**: If you encounter code, scripts, or orchestrators that do not provide immediate, observable utility to the current pipeline, you must aggressively delete them.
3. **Agent Autonomy over Static Code**: Prefer maintaining logic as Semantic Agent Skills (`SKILL.md`) rather than static shell scripts or bloated object-oriented code. The intelligence is in the prompt, not in the boilerplate.
4. **Action over Permission**: Do not stop to ask permission to refactor or delete if it objectively satisfies the YAGNI principle. Execute the cleanup natively.

## Modularity & Embedded External Tools
To strictly enforce this philosophy without polluting the global environment or requiring complex dependencies, Sovereign-OS embeds the complete source code for essential tools as Git Submodules directly under this skill:

### [Module: no-mistakes](modules/no-mistakes)
The complete repository for `no-mistakes` resides at `skills/ponytail/modules/no-mistakes/`.
This tool is the absolute filter against unearned complexity entering the codebase. 
- **Mandatory Gating**: All code changes MUST be pushed through the `no-mistakes` PR gate (`git push no-mistakes main`). This enforces that no slop, broken tests, or untested logic enters the repository.
- To update: run `cd skills/ponytail/modules/no-mistakes && git pull origin main`.

### [Module: codebase-memory-mcp](modules/codebase-memory-mcp)
The complete repository for `codebase-memory-mcp` resides at `skills/ponytail/modules/codebase-memory-mcp/`.
Do not guess how the codebase is structured. Do not use blind grepping when you need structural intelligence.
- **Mandatory Graph Tools**: Use `codebase-memory-mcp` tools (`search_graph`, `trace_path`, `get_code_snippet`) to build an exact, minimal understanding of the system before modifying it.
- To update: run `cd skills/ponytail/modules/codebase-memory-mcp && git pull origin main`.

## Capabilities Encompassed

The Ponytail skill handles the following specialized operational modes:

### 1. Ponytail Audit (Whole-Repo Scanning)
Scan the whole tree instead of a diff. Rank findings biggest cut first. 
- Hunt for dependencies the stdlib already ships, single-implementation interfaces, dead flags and config, and hand-rolled stdlib.
- Output one line per finding, ranked: `<tag> <what to cut>. <replacement>. [path]`.

### 2. Ponytail Review & Strict Gating
Review code diffs specifically for complexity and over-engineering.
- **Tags**: Use `delete:`, `stdlib:`, `native:`, `yagni:`, and `shrink:` to classify findings.
- **Goal**: Minimize the diff footprint. Delete more than you add.

### 3. Ponytail Debt (Complexity Tracking)
Maintain a strict ledger of technical debt.
- Track unearned complexity, speculative abstractions, and mock features.
- If a mock feature masquerades as production code, it is an "honest engineering" violation and must be flagged for immediate deletion.

### 4. Ponytail Gain (Efficiency Optimization)
Identify areas where native features can replace dependencies.
- Replace external tools with OS-level capabilities (e.g., OS file locks instead of Redis mutexes, native APIs instead of heavy libraries).

## Implementation Guide
When you are asked to implement something new, always ask yourself: *"Can this be achieved by giving an agent a semantic instruction instead of writing a new file?"* If yes, use the semantic instruction.
