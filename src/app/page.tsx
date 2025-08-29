import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function Home() {
  return (
    <main className="min-h-screen bg-orange-400 flex justify-center">
      <div className="w-full max-w-md px-4 py-16 text-center">
        <h1 className="text-4xl font-bold">cratedrop.fm</h1>
        <p className="mt-2 text-sm opacity-80">One random daily crate of small-artist tracks.</p>
        <a href="/api/health" className="inline-block mt-6 px-4 py-2 rounded-xl bg-black text-white">Health</a>
      </div>
    </main>
  );
}
