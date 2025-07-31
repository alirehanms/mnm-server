const express = require('express');
const fs = require('fs');

const app = express();
const socketPath = '/home/ubuntu/sockets/node.sock';

if (fs.existsSync(socketPath)) fs.unlinkSync(socketPath);

app.get('/', (req, res) => {
  res.send('Hello from Unix socket!');
});

app.listen(socketPath, () => {
  console.log(`Listening on ${socketPath}`);
  try {
    fs.chmodSync(socketPath, 0o777);
    console.log('Socket permissions set to 777');
  } catch (err) {
    console.error('Failed to set socket permissions:', err);
  }
});

app.on('error', (err) => {
  console.error('Express server error:', err);
});
