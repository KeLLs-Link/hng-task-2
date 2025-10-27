// server.js
const express = require('express');
const app = express();

const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;
const APP_POOL = (process.env.APP_POOL || 'blue').toLowerCase();
const RELEASE_ID = process.env.RELEASE_ID || 'unknown-release';

// chaos state object
let chaos = {
  enabled: false,
  mode: null // 'error' or 'timeout'
};

// helper to add headers
function addAppHeaders(res) {
  res.setHeader('X-App-Pool', APP_POOL);
  res.setHeader('X-Release-Id', RELEASE_ID);
}

app.use(express.json());

// GET /version
app.get('/version', async (req, res) => {
  if (chaos.enabled) {
    if (chaos.mode === 'error') {
      addAppHeaders(res);
      return res.status(500).json({ ok: false, reason: 'chaos-mode-error' });
    } else if (chaos.mode === 'timeout') {
      // delay longer than typical proxy/read timeouts (sleep)
      const delayMs = 12000; // 12 seconds
      await new Promise(resolve => setTimeout(resolve, delayMs));
      // after delay, respond normally (or you could still send 200)
      addAppHeaders(res);
      return res.json({ ok: true, pool: APP_POOL, release: RELEASE_ID, note: 'delayed-response' });
    }
  }

  // normal healthy response
  addAppHeaders(res);
  res.json({ ok: true, pool: APP_POOL, release: RELEASE_ID });
});

// POST /chaos/start?mode=error|timeout
app.post('/chaos/start', (req, res) => {
  const mode = (req.query.mode || '').toLowerCase();
  if (mode !== 'error' && mode !== 'timeout') {
    return res.status(400).json({ ok: false, error: 'mode must be error or timeout' });
  }
  chaos.enabled = true;
  chaos.mode = mode;
  // respond immediately
  res.json({ ok: true, chaos: { enabled: true, mode } });
  console.log(`Chaos started: ${mode}`);
});

// POST /chaos/stop
app.post('/chaos/stop', (req, res) => {
  chaos.enabled = false;
  chaos.mode = null;
  res.json({ ok: true, chaos: { enabled: false } });
  console.log('Chaos stopped');
});

// GET /healthz
app.get('/healthz', (req, res) => {
  // Always respond 200 if process alive; optionally tension later
  res.json({ ok: true, pool: APP_POOL, release: RELEASE_ID });
});

// root or other endpoints for convenience
app.get('/', (req, res) => {
  addAppHeaders(res);
  res.send(`Hello from ${APP_POOL} (release ${RELEASE_ID})\n`);
});

app.listen(PORT, () => {
  console.log(`${APP_POOL} app listening on port ${PORT} (release ${RELEASE_ID})`);
});
