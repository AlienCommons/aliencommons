import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const read = (path) => readFileSync(resolve(root, path), "utf8");
const assert = (condition, message) => {
  if (!condition) {
    throw new Error(message);
  }
};

const packageLicensePaths = [
  "apps/alienmark/LICENSE",
  "apps/backend/LICENSE",
  "apps/frontend/LICENSE",
  "packages/alienmark/LICENSE",
  "packages/drf-std-response/LICENSE",
];
const packageLicense = read(packageLicensePaths[0]);

assert(
  !existsSync(resolve(root, "LICENSE")),
  "The repository root must not contain a LICENSE file"
);
assert(
  packageLicense.startsWith("MIT License\n"),
  `${packageLicensePaths[0]} must contain the MIT License`
);
for (const path of packageLicensePaths.slice(1)) {
  assert(read(path) === packageLicense, `${path} must match the MIT License`);
}

for (const path of [
  "apps/alienmark/package.json",
  "apps/frontend/package.json",
  "packages/alienmark/package.json",
]) {
  const packageManifest = JSON.parse(read(path));
  assert(
    packageManifest.license === "MIT",
    `${path} must declare the MIT license`
  );
}

for (const path of [
  "apps/backend/pyproject.toml",
  "packages/drf-std-response/pyproject.toml",
]) {
  const project = read(path);
  assert(
    /^license = "MIT"$/mu.test(project),
    `${path} must declare the MIT license`
  );
  assert(
    /^license-files = \["LICENSE"\]$/mu.test(project),
    `${path} must include its LICENSE file`
  );
}

const packOutput = execFileSync(
  "npm",
  ["pack", "--dry-run", "--json", resolve(root, "packages/alienmark")],
  {
    encoding: "utf8",
    env: {
      ...process.env,
      npm_config_cache: resolve(tmpdir(), "aliencommons-npm-cache"),
    },
  }
);
const [pack] = JSON.parse(packOutput);
assert(
  pack?.files?.some(({ path }) => /^LICENSE(?:\.|$)/iu.test(path)),
  "The AlienMark npm package must contain a LICENSE file"
);

console.log("License audit passed.");
