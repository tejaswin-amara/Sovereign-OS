<div align="center">

  <h1>🔱 Sovereign OS <span style="color: #6C5CE7;">v15.0.2-Pure</span></h1>
  <p><strong>A personal PowerShell automation framework that governs how AI coding agents operate across workspaces.</strong></p>

  <p>
    <a href="#"><img src="https://img.shields.io/badge/version-v15.0.2--Pure-blue.svg?style=for-the-badge&logo=appveyor" alt="Version"></a>
    <a href="#"><img src="https://img.shields.io/badge/architecture-Minimal--Honest-purple.svg?style=for-the-badge" alt="Architecture"></a>
  </p>
</div>

---

> [!NOTE]
> **Sovereign OS has been sterilized.** The v15.0.2 release executes the ultimate Ponytail doctrine. The system has been reduced to an absolute minimum of components. There is zero unearned complexity.

## ⚡ The Four Pillars of Sovereign OS

### 1️⃣ Honest Engineering
Features that are described as working must be working. Silent degradation and mock features masquerading as production code are forbidden. One source of truth per fact.

### 2️⃣ Absolute Minimalism (The Ponytail Doctrine)
Zero bloat. Abstractions and wrapper scripts are violently pruned. The OS consists solely of a single Master Controller script (`sovereign.ps1`), a minimalistic configuration (`sovereign.config.json`), and raw Semantic Skills (`skills/`).

### 3️⃣ Semantic Execution
Agentic workflows are no longer driven by brittle PowerShell module wrappers. They are driven entirely by raw Markdown skills that agents parse and execute autonomously.

### 4️⃣ OS-Level Mutex Locking
The system safely guards the workspace by establishing an OS-level file lock, ensuring no concurrent operations can corrupt the environment.

---

## 🏗️ System Architecture

```mermaid
graph TD
    A[Sovereign Master Controller] -->|Locks System| B{Atomic Mutex}
    B -->|Verified| C[sovereign.config.json Verification]
    C -->|Passed| D[Semantic Skills Directory Sync]
```

---

## 🚀 Ignition

> [!WARNING]
> Ignition locks the execution environment. All external drift is blocked via an OS-level file stream lock.

To boot the Sovereign Master Controller:

```bash
pwsh -ExecutionPolicy Bypass -File "C:/Skills/sovereign.ps1"
```

---

<div align="center">
  <h3>Autonomously governed by the Sovereign Execution Engine.</h3>
  <p><i>"Small, correct, honest, and verified."</i></p>
</div>
