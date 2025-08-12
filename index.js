const express = require('express');
const { Server } = require('ws');
const { spawn } = require('child_process');
const app = express();
app.use(express.json());
const wss = new Server({ port: 8081 });
wss.on('connection', ws => {
  console.log('DB client connected');
  ws.on('message', () => {});
});
app.post('/deploy', (req, res) => {
  console.log('GitHub hook received');
  wss.clients.forEach(ws => ws.send('DEPLOY'));
  res.json({ ok: true });
});
app.listen(3000, () => console.log('MnM on :3000 & WS :8081'));
