import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { createConnection } from "node:net";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../", import.meta.url));
const manifest = JSON.parse(
  readFileSync(new URL("../package.json", import.meta.url), "utf8")
);
let failures = 0;

function check(name, passed, remedy) {
  console.log(
    `${passed ? "OK" : "FAIL"} ${name}${passed ? "" : ` — ${remedy}`}`
  );
  if (!passed) failures += 1;
}

function probe(command, args) {
  return spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    timeout: 15_000,
    stdio: ["ignore", "pipe", "pipe"],
  });
}

function portIsOccupied(host, port) {
  return new Promise((resolve) => {
    const socket = createConnection({ host, port });
    const finish = (occupied) => {
      socket.destroy();
      resolve(occupied);
    };
    socket.once("connect", () => finish(true));
    // A timeout is inconclusive: fail closed instead of reusing an unknown server.
    socket.setTimeout(1000, () => finish(true));
    socket.once("error", (error) =>
      finish(
        !["ECONNREFUSED", "EAFNOSUPPORT", "ENETUNREACH"].includes(error.code)
      )
    );
  });
}

const flags = new Set(process.argv.slice(2));
if ([...flags].some((flag) => !["--browser", "--docker"].includes(flag))) {
  console.error("Usage: node scripts/doctor.mjs [--browser] [--docker]");
  process.exit(2);
}

check(
  "Node 24",
  process.versions.node.startsWith("24."),
  "Use Node 24 (CI baseline)."
);
const pnpmVersion = manifest.packageManager.split("@")[1].split("+")[0];
check(
  `pnpm ${pnpmVersion}`,
  probe("pnpm", ["--version"]).stdout?.trim() === pnpmVersion,
  "Enable Corepack and install the version pinned in package.json."
);
check(
  "uv",
  probe("uv", ["--version"]).status === 0,
  "Install uv; see the setup guide."
);
check(
  "Node dependencies and Nuxt generated types",
  existsSync(
    new URL("../node_modules/vite-plus/package.json", import.meta.url)
  ) &&
    existsSync(
      new URL("../apps/frontend/.nuxt/tsconfig.app.json", import.meta.url)
    ),
  "Run pnpm install --frozen-lockfile."
);
const python = probe("uv", [
  "run",
  "--locked",
  "--no-sync",
  "--package",
  "aliencommons-backend",
  "python",
  "-c",
  "import sys, django, rest_framework; assert sys.version_info[:2] == (3, 14); print('ready')",
]);
check(
  "Python 3.14 and backend dependencies",
  python.status === 0,
  "Run uv sync --locked --all-packages --dev (Python 3.14)."
);

if (flags.has("--browser")) {
  try {
    const requireFrontend = createRequire(
      new URL("../apps/frontend/package.json", import.meta.url)
    );
    const { chromium } = requireFrontend("@playwright/test");
    check(
      "Playwright Chromium",
      existsSync(chromium.executablePath()),
      "Run pnpm --filter frontend exec playwright install chromium."
    );
  } catch {
    check(
      "Playwright dependency",
      false,
      "Run pnpm install --frozen-lockfile."
    );
  }
  console.log(
    "INFO Browser tests own 127.0.0.1 ports 43100 and 43101; stop demo servers first."
  );
  for (const port of [43100, 43101]) {
    const occupied = await Promise.all([
      portIsOccupied("127.0.0.1", port),
      portIsOccupied("::1", port),
    ]);
    check(
      `Browser port ${port}`,
      !occupied.some(Boolean),
      "Stop the process using this test port."
    );
  }
}
if (flags.has("--docker")) {
  check(
    "Docker Compose",
    probe("docker", ["compose", "version"]).status === 0,
    "Install Docker Compose."
  );
  check(
    "Docker daemon",
    probe("docker", ["info"]).status === 0,
    "Start Docker before make dev-up."
  );
}

const gitnexus = probe("gitnexus", ["--version"]);
console.log(
  `INFO GitNexus ${gitnexus.status === 0 ? "CLI available; verify index freshness separately" : "optional CLI unavailable; use the documented manual impact analysis"}.`
);
console.log(
  failures
    ? `${failures} required check(s) failed.`
    : "Development prerequisites are ready."
);
process.exitCode = failures ? 1 : 0;
