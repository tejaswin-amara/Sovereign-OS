export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24 bg-slate-950 text-white">
      <h1 className="text-4xl font-bold mb-4">Sovereign-OS Dashboard</h1>
      <p className="text-xl text-slate-400">
        Knowledge Graph and Agent Orchestration UI
      </p>
      <div className="mt-8 border border-slate-800 p-8 rounded-lg bg-slate-900 shadow-xl">
        <p className="font-mono text-sm text-green-400">
          [System] UI Engine online. Next.js, Tailwind, Shadcn-UI integrated.
        </p>
      </div>
    </main>
  );
}
