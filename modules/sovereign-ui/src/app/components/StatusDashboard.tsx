"use client";

import { Activity, ShieldCheck, Database, Cpu } from "lucide-react";
import { useEffect, useState } from "react";

export function StatusDashboard() {
  const [data, setData] = useState({
    status: "CONNECTING...",
    lock: "PENDING",
    modules_count: 0,
    agents_count: 0
  });

  useEffect(() => {
    const interval = setInterval(() => {
      fetch('/api/status')
        .then(res => res.json())
        .then(setData)
        .catch(console.error);
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="grid grid-cols-1 md:grid-cols-4 gap-4 w-full max-w-5xl mb-8">
      {[
        { title: "Daemon Status", value: data.status, icon: Activity, color: "text-green-400" },
        { title: "Lock Status", value: data.lock, icon: ShieldCheck, color: "text-blue-400" },
        { title: "Active Modules", value: `${data.modules_count} Modules`, icon: Database, color: "text-purple-400" },
        { title: "Active Agents", value: `${data.agents_count} Agents`, icon: Cpu, color: "text-orange-400" },
      ].map((stat, idx) => (
        <div key={idx} className="p-4 border border-slate-800 bg-slate-900 rounded-xl flex items-center justify-between shadow-sm transition-all">
          <div>
            <p className="text-slate-400 text-xs font-mono mb-1">{stat.title}</p>
            <p className={`text-xl font-bold ${stat.color}`}>{stat.value}</p>
          </div>
          <stat.icon className={`w-8 h-8 ${stat.color} opacity-50`} />
        </div>
      ))}
    </div>
  );
}
