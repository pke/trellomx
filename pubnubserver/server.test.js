const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const http = require('node:http');
const { test } = require('node:test');

test('server starts with the configured PubNub client', async (t) => {
  const child = spawn(process.execPath, ['server.js'], {
    cwd: __dirname,
    env: { ...process.env, port: '0' },
  });

  t.after(() => child.kill());

  let output = '';
  child.stdout.on('data', (chunk) => {
    output += chunk;
  });
  child.stderr.on('data', (chunk) => {
    output += chunk;
  });

  const outcome = await Promise.race([
    new Promise((resolve) => {
      child.stdout.on('data', (chunk) => {
        if (chunk.includes('Trello2PubNub Proxy running on 0')) {
          resolve('started');
        }
      });
    }),
    new Promise((resolve) => {
      child.once('exit', (code) => resolve(`exited with code ${code}`));
    }),
    new Promise((resolve) => setTimeout(() => resolve('timed out'), 3000)),
  ]);

  assert.equal(outcome, 'started', output);
});

test('POST publishes the webhook payload to the requested channel', async (t) => {
  const { createProxyServer } = require('./server');
  const publishes = [];
  const pubnub = {
    publish: async (request) => {
      publishes.push(request);
    },
  };
  const logger = { info() {}, log() {}, error() {} };
  const server = createProxyServer(pubnub, logger);

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(() => server.close());

  const message = { action: { type: 'createCard' } };
  const response = await new Promise((resolve, reject) => {
    const request = http.request({
      hostname: '127.0.0.1',
      port: server.address().port,
      path: '/trello-events',
      method: 'POST',
      headers: { 'content-type': 'application/json' },
    }, resolve);
    request.on('error', reject);
    request.end(JSON.stringify(message));
  });

  assert.equal(response.statusCode, 200);
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(publishes, [{ channel: 'trello-events', message }]);
});
