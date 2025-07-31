const express = require('express');
const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const app = express();
app.use(express.json());

const PROTO_PATH = './mnm.proto';
const packageDefinition = protoLoader.loadSync(PROTO_PATH);
const mnmProto = grpc.loadPackageDefinition(packageDefinition).mnm;

// Store connected clients
let clients = [];

function notifyClients() {
  clients.forEach(client => {
    client.Notify({}, (err, res) => {
      if (err) console.error('Notify error:', err);
      else console.log('Notified client');
    });
  });
}

app.post('/deploy', (req, res) => {
  console.log('Received deploy event:', req.body);
  notifyClients();
  res.sendStatus(200);
});

// gRPC server for clients to connect
function main() {
  const server = new grpc.Server();
  server.addService(mnmProto.Deploy.service, {
    Notify: (call, callback) => {
      console.log('Client connected for Notify');
      clients.push(call);
      callback(null, {});
    }
  });
  server.bindAsync('0.0.0.0:50051', grpc.ServerCredentials.createInsecure(), () => {
    server.start();
    app.listen(3000, () => console.log('MnM server HTTP on 3000, gRPC on 50051'));
  });
}

main();
