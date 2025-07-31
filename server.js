// ~/mnm-server/server.js
const express = require('express');
const WebSocket = require('ws');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

// Use JSON middleware
app.use(bodyParser.json());

// WebSocket server
const wss = new WebSocket.Server({ port: 4000 });
let clients = [];

wss.on('connection', (ws) => {
  clients.push(ws);
  console.log('Client connected to WebSocket');

  ws.on('close', () => {
    clients = clients.filter(c => c !== ws);
    console.log('Client disconnected');
  });
});

// Handle GitHub webhook
app.post('/deploy', (req, res) => {
  console.log('Received POST from GitHub:', req.body);

  // Notify all clients
  clients.forEach(ws => {
    ws.send(JSON.stringify({ type: 'deploy', data: req.body }));
  });

  res.sendStatus(200);
});

app.listen(port, () => {
  console.log(`MnM Server listening on port ${port}`);
  console.log(`WebSocket Server listening on port 4000`);
});
