import fs from 'fs';
import https from 'https';
import http from 'http';

const WEBHOOK_URL = process.env.WEBHOOK_URL;
const BOT_TOKEN = process.env.DISCORD_BOT_TOKEN;
const MANUAL_ID = process.env.MANUAL_BOT_ID;
const DB_PATH = process.env.DB_PATH || 'database.json';

const REQUEST_TIMEOUT_MS = 15000;

function httpsRequest(options, body = null, protocol = 'https:') {
  const client = protocol === 'http:' ? http : https;
  return new Promise((resolve) => {
    const req = client.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    });
    req.setTimeout(REQUEST_TIMEOUT_MS, () => {
      req.destroy(new Error('Request timed out'));
    });
    req.on('error', (e) => resolve({ status: 0, body: e.message }));
    if (body) req.write(body);
    req.end();
  });
}

async function postJson(urlString, payload, extraHeaders = {}) {
  const url = new URL(urlString);
  const body = JSON.stringify(payload);
  return httpsRequest(
    {
      hostname: url.hostname,
      port: url.port || undefined,
      path: url.pathname + url.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        ...extraHeaders
      }
    },
    body,
    url.protocol
  );
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function sendToDiscord(title, message) {
  const payload = {
    content: message,
    thread_name: title,
    username: 'Leaf'
  };

  let res = await postJson(`${WEBHOOK_URL}?wait=true`, payload);

  // Respect Discord rate limits (429) once before giving up.
  if (res.status === 429) {
    let retryAfterMs = 2000;
    try {
      const parsed = JSON.parse(res.body);
      if (typeof parsed.retry_after === 'number') retryAfterMs = parsed.retry_after * 1000;
    } catch {}
    console.warn(`Rate limited by Discord, retrying in ${retryAfterMs}ms`);
    await sleep(Math.min(retryAfterMs, 60000));
    res = await postJson(`${WEBHOOK_URL}?wait=true`, payload);
  }

  if (res.status < 200 || res.status >= 300) {
    console.error(`Discord webhook error: ${res.status} - ${res.body}`);
    return { success: false };
  }

  let parsed;
  try {
    parsed = JSON.parse(res.body);
  } catch {
    console.error('Webhook returned non-JSON body:', res.body);
    return { success: false };
  }

  console.log(`Sent! Message ID: ${parsed.id}, Channel: ${parsed.channel_id}`);

  if (BOT_TOKEN) {
    await sleep(1500);
    const emoji = encodeURIComponent('\u{1F525}');
    const reaction = await httpsRequest({
      hostname: 'discord.com',
      path: `/api/v10/channels/${parsed.channel_id}/messages/${parsed.id}/reactions/${emoji}/@me`,
      method: 'PUT',
      headers: {
        Authorization: `Bot ${BOT_TOKEN}`,
        'Content-Length': '0'
      }
    });
    if (reaction.status === 204) {
      console.log('Reaction \u{1F525} added');
    } else {
      console.error(`Reaction failed: ${reaction.status} - ${reaction.body}`);
    }
  }

  return { success: true };
}

function markSent(bot, now) {
  bot.sent = true;
  bot.status = 'sent';
  bot.sentTime = now.toISOString();
  bot.scheduled = false;
}

async function run() {
  if (!fs.existsSync(DB_PATH)) {
    console.error('database.json not found');
    return;
  }

  let db;
  try {
    db = JSON.parse(fs.readFileSync(DB_PATH, 'utf8'));
  } catch (e) {
    console.error('Failed to parse database.json:', e.message);
    return;
  }

  const now = new Date();
  let dirty = false;

  if (!db.bots) db.bots = {};

  if (MANUAL_ID && db.bots[MANUAL_ID]) {
    const bot = db.bots[MANUAL_ID];
    if (!bot.sent && !bot.cancelled) {
      console.log(`Manual trigger for: ${bot.title}`);
      const result = await sendToDiscord(bot.title, bot.message);
      if (result.success) {
        markSent(bot, now);
        dirty = true;
      }
    } else {
      console.log(`Bot ${MANUAL_ID} already sent or cancelled, skipping`);
    }
  }

  const due = Object.entries(db.bots).filter(([, bot]) => {
    if (bot.sent || bot.cancelled || bot.isProcessing) return false;
    if (!bot.scheduled || !bot.scheduledTime) return false;
    const t = new Date(bot.scheduledTime).getTime();
    return !Number.isNaN(t) && t <= now.getTime();
  });

  // Oldest scheduled messages first.
  due.sort(([, a], [, b]) => new Date(a.scheduledTime) - new Date(b.scheduledTime));

  for (const [id, bot] of due) {
    console.log(`Processing scheduled (${id}): ${bot.title}`);
    const result = await sendToDiscord(bot.title, bot.message);
    if (result.success) {
      markSent(bot, now);
      dirty = true;
    }
    await sleep(1000);
  }

  if (dirty) {
    fs.writeFileSync(DB_PATH, JSON.stringify(db, null, 2));
    console.log('Changes saved to database.json');
  } else {
    console.log('Nothing to send');
  }
}

run().catch((e) => {
  console.error('Unexpected error:', e);
});
