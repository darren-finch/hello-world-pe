"use client";

import { useState } from "react";

export default function Home() {
  const [count, setCount] = useState(0);

  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-50 font-sans dark:bg-black">
      <main className="flex flex-col items-center gap-8">
        <h1 className="text-4xl font-bold tracking-tight text-black dark:text-white">
          Hello, World!
        </h1>
        <div className="flex items-center gap-6">
          <button
            onClick={() => setCount((c) => c - 1)}
            className="flex h-12 w-12 items-center justify-center rounded-full border border-black/10 text-2xl font-medium transition-colors hover:bg-black/5 dark:border-white/20 dark:text-white dark:hover:bg-white/10"
            aria-label="Decrease"
          >
            −
          </button>
          <span className="w-16 text-center text-5xl font-semibold tabular-nums text-black dark:text-white">
            {count}
          </span>
          <button
            onClick={() => setCount((c) => c + 1)}
            className="flex h-12 w-12 items-center justify-center rounded-full border border-black/10 text-2xl font-medium transition-colors hover:bg-black/5 dark:border-white/20 dark:text-white dark:hover:bg-white/10"
            aria-label="Increase"
          >
            +
          </button>
        </div>
        <p className="text-sm text-zinc-500 dark:text-zinc-400">
          Counter value will be loaded from Redis in future.
        </p>
      </main>
    </div>
  );
}
