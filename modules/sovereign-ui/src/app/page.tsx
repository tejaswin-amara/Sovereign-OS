import { Shield, Cpu, Terminal } from "lucide-react";
import { StatusDashboard } from "./components/StatusDashboard";
import { AgentTable } from "./components/AgentTable";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center p-12 bg-slate-950 text-white font-sans selection:bg-blue-900/50">
      <div className="w-full max-w-5xl flex items-center justify-between mb-12">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-blue-900/20 border border-blue-500/30 rounded-2xl shadow-[0_0_30px_rgba(59,130,246,0.15)]">
            <Shield className="w-10 h-10 text-blue-400" />
          </div>
          <div>
            <h1 className="text-3xl font-bold tracking-tight bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
              Sovereign-OS
            </h1>
            <p className="text-slate-400 flex items-center gap-2 font-mono text-sm mt-1">
              <Cpu className="w-4 h-4 text-purple-400" />
              v16.0.0 // Command Center
            </p>
          </div>
        </div>
      </div>

      <StatusDashboard />
      <AgentTable />

      <div className="mt-8 border border-slate-800 p-6 rounded-xl bg-slate-900/50 shadow-xl max-w-5xl w-full">
        <div className="flex items-center gap-2 mb-2 font-mono text-sm text-green-400">
          <Terminal className="w-4 h-4 text-green-400" />
          <span>[System] Real-time data stream established via IPC socket.</span>
        </div>
        <p className="text-slate-500 text-xs font-mono ml-6">
          Awaiting daemon commands...
        </p>
      </div>
    </main>
  );
}
