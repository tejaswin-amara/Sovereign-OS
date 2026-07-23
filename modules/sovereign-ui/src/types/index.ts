/**
 * Sovereign-OS V17 — Complete TypeScript Type Definitions
 * System-wide contracts for UI, APIs, and State Management.
 */

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
