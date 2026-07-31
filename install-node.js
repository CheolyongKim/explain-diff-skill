#!/usr/bin/env node
// Install script for explain-diff-skill (Hermes Agent skills)
// Runs on `npm i -g explain-diff-skill` then `explain-diff-skill`, or `npx explain-diff-skill`.
// Downloads the `skills/` files directly from GitHub (git tree API + raw URLs)
// and writes them into the Hermes skills folder. No archive extraction.

const https = require('node:https');
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
    path.join(os.homedir(), 'AppData', 'Local', 'hermes', 'skills'),
    path.join(os.homedir(), 'AppData', 'Roaming', 'hermes', 'skills'),
    path.join(os.homedir(), 'Library', 'Application Support', 'hermes', 'skills'),
    path.join(process.env.XDG_DATA_HOME || path.join(os.homedir(), '.local', 'share'), 'hermes', 'skills'),
    path.join(os.homedir(), '.hermes', 'skills'),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  return candidates[0];
}

function getJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'explain-diff-installer' } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return resolve(getJson(res.headers.location));
      }
      if (res.statusCode !== 200) {
        let body = '';
        res.on('data', (d) => (body += d));
        res.on('end', () => reject(new Error(`GET ${url} -> ${res.statusCode} ${body.slice(0, 200)}`)));
        return;
      }
      let body = '';
      res.setEncoding('utf8');
      res.on('data', (d) => (body += d));
      res.on('end', () => resolve(JSON.parse(body)));
    }).on('error', reject);
  });
}

function getText(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'explain-diff-installer' } }, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        return resolve(getText(res.headers.location));
      }
      if (res.statusCode !== 200) {
        let body = '';
        res.on('data', (d) => (body += d));
        res.on('end', () => reject(new Error(`GET ${url} -> ${res.statusCode}`)));
        return;
      }
      const chunks = [];
      res.on('data', (d) => chunks.push(d));
      res.on('end', () => resolve(Buffer.concat(chunks)));
    }).on('error', reject);
  });
}

async function main() {
  const target = findHermesSkills();
  fs.mkdirSync(target, { recursive: true });

  console.log(`Resolving file tree for ${REPO}@${BRANCH} ...`);
  const tree = await getJson(`https://api.github.com/repos/${REPO}/git/trees/${BRANCH}?recursive=1`);
  const blobs = (tree.tree || []).filter(
    (x) => x.type === 'blob' && x.path.startsWith(SKILLS_DIR + '/')
  );
  if (blobs.length === 0) {
    console.error(`No files found under ${SKILLS_DIR}/ in the repo tree.`);
    process.exit(1);
  }

  const copied = new Set();
  for (const b of blobs) {
    const url = `https://raw.githubusercontent.com/${REPO}/${BRANCH}/${b.path}`;
    const dest = path.join(target, b.path);
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    const buf = await getText(url);
    fs.writeFileSync(dest, buf);
    copied.add(b.path.split('/')[1]);
  }

  console.log('\nexplain-diff-skill installed.');
  console.log('Skills folder:', target);
  [...copied].sort().forEach((c) => console.log('  -', c));
  console.log('\nRestart Hermes Agent (or run /skills) to load the new skills.');
}

main().catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
