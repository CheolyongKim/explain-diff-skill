#!/usr/bin/env node
// Install script for explain-diff-skill (Hermes Agent skills)
// Runs when you execute `npm i -g explain-diff-skill` and then `explain-diff-skill`,
// or directly via `npx explain-diff-skill`.
// It copies the `skills/` directory from the GitHub repo into the Hermes skills folder.

const { execFileSync, spawnSync } = require('node:child_process');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

const REPO = 'CheolyongKim/explain-diff-skill';
const BRANCH = 'main';
const SKILLS_DIR = 'skills';

function findHermesSkills() {
  if (process.env.HERMES_SKILLS_DIR && fs.existsSync(process.env.HERMES_SKILLS_DIR)) {
    return process.env.HERMES_SKILLS_DIR;
  }
  const candidates = [
    path.join(os.homedir(), 'AppData', 'Local', 'hermes', 'skills'),     // Windows
    path.join(os.homedir(), 'AppData', 'Roaming', 'hermes', 'skills'),   // Windows (alt)
    path.join(os.homedir(), 'Library', 'Application Support', 'hermes', 'skills'), // macOS
    path.join(process.env.XDG_DATA_HOME || path.join(os.homedir(), '.local', 'share'), 'hermes', 'skills'), // Linux
    path.join(os.homedir(), '.hermes', 'skills'),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  return candidates[0];
}

function run(cmd, args, opts = {}) {
  return execFileSync(cmd, args, { stdio: 'pipe', ...opts }).toString().trim();
}

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, entry.name);
    const d = path.join(dest, entry.name);
    if (entry.isDirectory()) copyDir(s, d);
    else fs.copyFileSync(s, d);
  }
}

function main() {
  const target = findHermesSkills();
  fs.mkdirSync(target, { recursive: true });

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'explain-diff-'));
  const cleanup = () => fs.rmSync(tmp, { recursive: true, force: true });
  process.on('exit', cleanup);

  let repoRoot;
  // Prefer git sparse clone (dependency-free, no zip parsing).
  try {
    const cloneUrl = `https://github.com/${REPO}.git`;
    run('git', ['clone', '--depth', '1', '--filter=blob:none', '--sparse', cloneUrl, tmp]);
    run('git', ['-C', tmp, 'sparse-checkout', 'set', SKILLS_DIR]);
    repoRoot = tmp;
  } catch {
    // Fallback: download the zip and extract with native tools.
    const url = `https://github.com/${REPO}/archive/refs/heads/${BRANCH}.zip`;
    const zip = path.join(tmp, 'repo.zip');
    console.log('Downloading', `${REPO}@${BRANCH}`, '...');
    const res = spawnSync('curl', ['-fsSL', url, '-o', zip], { stdio: 'inherit' });
    if (res.status !== 0) {
      // try node's fetch
      const f = run('node', ['-e', `fetch(${JSON.stringify(url)}).then(r=>r.arrayBuffer()).then(b=>require('fs').writeFileSync(${JSON.stringify(zip)},Buffer.from(b)))`]);
      void f;
    }
    const extracted = path.join(tmp, 'extracted');
    fs.mkdirSync(extracted, { recursive: true });
    if (process.platform === 'win32') {
      run('powershell', ['-NoProfile', '-Command', `Expand-Archive -Force ${JSON.stringify(zip)} ${JSON.stringify(extracted)}`]);
    } else {
      run('unzip', ['-q', zip, '-d', extracted]);
    }
    const top = fs.readdirSync(extracted).find(n => fs.statSync(path.join(extracted, n)).isDirectory());
    repoRoot = path.join(extracted, top);
  }

  const src = path.join(repoRoot, SKILLS_DIR);
  if (!fs.existsSync(src)) {
    console.error('Could not find', `${SKILLS_DIR}/`, 'in the downloaded repo.');
    process.exit(1);
  }

  const copied = [];
  for (const name of fs.readdirSync(src, { withFileTypes: true })) {
    if (!name.isDirectory()) continue;
    copyDir(path.join(src, name.name), path.join(target, name.name));
    copied.push(name.name);
  }

  console.log('\nexplain-diff-skill installed.');
  console.log('Skills folder:', target);
  copied.forEach(c => console.log('  -', c));
  console.log('\nRestart Hermes Agent (or run /skills) to load the new skills.');
}

try {
  main();
} catch (e) {
  console.error(e.message || e);
  process.exit(1);
}
