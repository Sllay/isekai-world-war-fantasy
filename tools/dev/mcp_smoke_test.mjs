#!/usr/bin/env node
import { spawn } from 'node:child_process';
import readline from 'node:readline';

const MCP_PACKAGE = '@satelliteoflove/godot-mcp@4.1.11';
const EXPECTED_GODOT = '4.7.2';
const TIMEOUT_MS = 30000;

const child = spawn('npx', ['-y', MCP_PACKAGE], {
  stdio: ['pipe', 'pipe', 'pipe'],
  env: {
    ...process.env,
    GODOT_HOST: process.env.GODOT_HOST ?? '127.0.0.1',
    GODOT_PORT: process.env.GODOT_PORT ?? '6550',
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
