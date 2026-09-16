/// <reference types="node" />

import { defineConfig, devices } from "@playwright/test";
import process from "node:process";

export default defineConfig({
  testDir: "./e2e",
  testMatch: "**/*.e2e.ts",
  fullyParallel: false,
  forbidOnly: Boolean(process.env.CI),
  retries: 0,
  workers: 1,
  timeout: 60_000,
  expect: { timeout: 10_000 },
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    baseURL: "http://127.0.0.1:43100",
    locale: "en-US",
    screenshot: "only-on-failure",
    trace: "retain-on-failure",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: [
    {
      command:
        "uv run --locked --package aliencommons-backend python scripts/browser-backend.py",
      cwd: "../..",
      url: "http://127.0.0.1:43101/v1/sessions/csrf/",
      reuseExistingServer: false,
      timeout: 120_000,
      gracefulShutdown: { signal: "SIGTERM", timeout: 5000 },
    },
    {
      command: "pnpm dev --host 127.0.0.1 --port 43100",
      url: "http://127.0.0.1:43100/login",
      env: {
        NUXT_API_INTERNAL_BASE: "http://127.0.0.1:43101",
        NUXT_PUBLIC_API_BASE: "/api",
        NUXT_PUBLIC_I18N_BASE_URL: "http://127.0.0.1:43100",
        NUXT_TELEMETRY_DISABLED: "1",
      },
      reuseExistingServer: false,
      timeout: 180_000,
      stdout: "pipe",
      gracefulShutdown: { signal: "SIGTERM", timeout: 5000 },
    },
  ],
});
