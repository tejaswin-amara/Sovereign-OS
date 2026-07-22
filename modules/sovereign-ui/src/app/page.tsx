import { Shield, Activity, Cpu, Terminal } from "lucide-react";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24 bg-slate-950 text-white">
      <div className="flex items-center gap-3 mb-4">
        <Shield className="w-10 h-10 text-blue-500" />
        <h1 className="text-4xl font-bold">Sovereign-OS Dashboard</h1>
      </div>
      <p className="text-xl text-slate-400 flex items-center gap-2">
        <Cpu className="w-5 h-5 text-purple-400" />
        Knowledge Graph and Agent Orchestration UI
      </p>
      <div className="mt-8 border border-slate-800 p-8 rounded-lg bg-slate-900 shadow-xl max-w-lg w-full">
        <div className="flex items-center gap-2 mb-3 font-mono text-sm text-green-400">
          <Terminal className="w-4 h-4 text-green-400" />
          <span>[System] UI Engine online. Next.js, Tailwind, Shadcn-UI integrated.</span>
        </div>
        <div className="flex items-center gap-2 text-slate-400 text-xs font-mono">
          <Activity className="w-4 h-4 text-blue-400" />
          <span>Lucide-React icon asset stream active.</span>
        </div>
      </div>
    </main>
  );
}
