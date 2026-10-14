#!/usr/bin/env node
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import net from 'node:net';
import path from 'node:path';
import readline from 'node:readline';
import { fileURLToPath } from 'node:url';

const MCP_PACKAGE = '@satelliteoflove/godot-mcp@4.1.11';
const EXPECTED_GODOT = '4.7.2';
const TIMEOUT_MS = 30000;
const HOST = process.env.GODOT_HOST ?? '127.0.0.1';
const PORT = Number(process.env.GODOT_PORT ?? '6550');

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(HERE, '../..');
const LOCAL_DIR = path.join(ROOT_DIR, '.codex-local');
const PID_FILE = path.join(LOCAL_DIR, 'godot-editor.pid');
const LOG_FILE = path.join(LOCAL_DIR, 'godot-editor.log');

if (!(await canConnect(HOST, PORT))) {
  printEditorDiagnostics();
  console.error(
    `FAIL: Godot bridge is not listening at ${HOST}:${PORT} before the smoke test starts.\n` +
    'Start the editor from a persistent shell/terminal, not from a short-lived agent command, then retry.'
  );
  process.exit(1);
}

console.log(`Preflight: Godot bridge is listening at ${HOST}:${PORT}`);

const child = spawn('npx', ['-y', MCP_PACKAGE], {
  stdio: ['pipe', 'pipe', 'pipe'],
  env: {
    ...process.env,
    GODOT_HOST: HOST,
    GODOT_PORT: String(PORT),
    GODOT_MCP_USAGE_LOG: '0',
  },
});

let finished = false;
const timer = setTimeout(() => fail('Timed out waiting for MCP responses.'), TIMEOUT_MS);

child.stderr.on('data', (chunk) => {
  process.stderr.write(`[godot-mcp] ${chunk}`);
});

child.on('exit', (code, signal) => {
  if (!finished) {
    fail(`godot-mcp exited early (code=${code}, signal=${signal}).`);
  }
});

const rl = readline.createInterface({ input: child.stdout });
rl.on('line', (line) => {
  if (!line.trim()) return;

  let msg;
  try {
    msg = JSON.parse(line);
  } catch {
    process.stderr.write(`[non-json stdout] ${line}\n`);
    return;
  }

  if (msg.id === 1) {
    if (msg.error) return fail(`Initialize failed: ${JSON.stringify(msg.error)}`);

    const version = msg?.result?.serverInfo?.version ?? 'unknown';
    console.log(`MCP server initialized: godot-mcp ${version}`);

    send({
      jsonrpc: '2.0',
      method: 'notifications/initialized',
      params: {},
    });

    send({
      jsonrpc: '2.0',
      id: 2,
      method: 'tools/call',
      params: {
        name: 'godot_editor_read',
        arguments: { action: 'get_state' },
      },
    });
    return;
  }

  if (msg.id === 2) {
    if (msg.error) return fail(`Godot tool call failed: ${JSON.stringify(msg.error)}`);

    const text = msg?.result?.content?.find((entry) => entry.type === 'text')?.text;
    if (!text) return fail(`Tool returned no text state: ${JSON.stringify(msg.result)}`);

    let state;
    try {
      state = JSON.parse(text);
    } catch {
      return fail(`Could not parse Godot editor state: ${text}`);
    }

    const version = String(state.godot_version ?? 'unknown');
    if (!version.startsWith(EXPECTED_GODOT)) {
      return fail(`Expected Godot ${EXPECTED_GODOT}, got ${version}`);
    }

    console.log(`Godot editor reachable: ${version}`);
    console.log(`Current scene: ${state.current_scene ?? '(none)'}`);
    console.log(`Playing: ${Boolean(state.is_playing)}`);
    console.log('PASS: MCP stdio -> WebSocket bridge -> Godot editor is healthy.');
    succeed();
  }
});

function send(payload) {
  child.stdin.write(`${JSON.stringify(payload)}\n`);
}

function succeed() {
  if (finished) return;
  finished = true;
  clearTimeout(timer);
  rl.close();
  child.kill('SIGTERM');
  setTimeout(() => process.exit(0), 50);
}

function fail(message) {
  if (finished) return;
  finished = true;
  clearTimeout(timer);
  console.error(`FAIL: ${message}`);
  try { child.kill('SIGTERM'); } catch {}
  setTimeout(() => process.exit(1), 50);
}

function canConnect(host, port) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host, port });
    const finish = (value) => {
      socket.removeAllListeners();
      socket.destroy();
      resolve(value);
    };
    socket.setTimeout(1200);
    socket.once('connect', () => finish(true));
    socket.once('timeout', () => finish(false));
    socket.once('error', () => finish(false));
  });
}

function printEditorDiagnostics() {
  if (fs.existsSync(PID_FILE)) {
    const pid = fs.readFileSync(PID_FILE, 'utf8').trim();
    let alive = false;
    try {
      process.kill(Number(pid), 0);
      alive = true;
    } catch {}
    console.error(`Editor launcher PID: ${pid} (${alive ? 'alive' : 'not running'})`);
  } else {
    console.error('Editor launcher PID: no pid file found');
  }

  if (fs.existsSync(LOG_FILE)) {
    const lines = fs.readFileSync(LOG_FILE, 'utf8').split(/\r?\n/);
    const tail = lines.slice(-40).join('\n').trim();
    if (tail) {
      console.error('--- last Godot editor log lines ---');
      console.error(tail);
      console.error('--- end Godot editor log ---');
    }
  } else {
    console.error('Godot editor log: not found');
  }
}

send({
  jsonrpc: '2.0',
  id: 1,
  method: 'initialize',
  params: {
    protocolVersion: '2024-11-05',
    capabilities: {},
    clientInfo: { name: 'isekai-mcp-smoke', version: '1' },
  },
});
