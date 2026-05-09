#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const path = require("node:path");

const scriptPath = path.resolve(__dirname, "..", "pk-awesome-review.ps1");
const args = process.argv.slice(2);

function runWithShell(binary) {
  const result = spawnSync(
    binary,
    ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath, ...args],
    { stdio: "inherit" }
  );
  return result;
}

let result = runWithShell("pwsh");
if (result.error && process.platform === "win32") {
  result = runWithShell("powershell");
}

if (result.error) {
  throw result.error;
}

process.exit(result.status ?? 0);
