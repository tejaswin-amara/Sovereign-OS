import { CheckCircle2, Clock, XCircle } from "lucide-react";

export function AgentTable() {
  const agents = [
    { id: "agt-001", role: "UI Fixer", status: "Running", time: "2m 14s", type: "Active" },
    { id: "agt-002", role: "CI Pipeline", status: "Parked", time: "10m 00s", type: "Needs Approval" },
    { id: "agt-003", role: "DB Auditor", status: "Failed", time: "0m 45s", type: "Error" },
  ];

  return (
    <div className="w-full max-w-5xl border border-slate-800 bg-slate-900 rounded-xl overflow-hidden shadow-xl">
      <div className="p-4 border-b border-slate-800 bg-slate-950 flex justify-between items-center">
        <h2 className="font-mono text-sm text-slate-300">Active Agent Roster</h2>
        <span className="px-2 py-1 bg-blue-900/30 text-blue-400 text-xs rounded-full border border-blue-800/50">Auto-refreshing</span>
      </div>
      <table className="w-full text-left border-collapse">
        <thead>
          <tr className="bg-slate-900 text-slate-400 text-xs uppercase font-mono border-b border-slate-800">
            <th className="px-4 py-3 font-normal">Agent ID</th>
            <th className="px-4 py-3 font-normal">Role</th>
            <th className="px-4 py-3 font-normal">Status</th>
            <th className="px-4 py-3 font-normal">Uptime</th>
          </tr>
        </thead>
        <tbody className="text-sm text-slate-300 font-mono">
          {agents.map((agent) => (
            <tr key={agent.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors">
              <td className="px-4 py-3 text-blue-400">{agent.id}</td>
              <td className="px-4 py-3">{agent.role}</td>
              <td className="px-4 py-3 flex items-center gap-2">
                {agent.status === "Running" && <CheckCircle2 className="w-4 h-4 text-green-400" />}
                {agent.status === "Parked" && <Clock className="w-4 h-4 text-orange-400" />}
                {agent.status === "Failed" && <XCircle className="w-4 h-4 text-red-400" />}
                <span className={
                  agent.status === "Running" ? "text-green-400" :
                  agent.status === "Parked" ? "text-orange-400" : "text-red-400"
                }>{agent.type}</span>
              </td>
              <td className="px-4 py-3 text-slate-500">{agent.time}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
