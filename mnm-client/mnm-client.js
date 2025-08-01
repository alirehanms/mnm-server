const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const simpleGit = require('simple-git');
const PROTO_PATH = './mnm.proto';

const packageDefinition = protoLoader.loadSync(PROTO_PATH);
const mnmProto = grpc.loadPackageDefinition(packageDefinition).mnm;

const client = new mnmProto.Deploy('95.216.209.142:50051', grpc.credentials.createInsecure());

function listenForNotify() {
  client.Notify({}, (err, res) => {
    if (err) {
      console.error('Notify error:', err);
    } else {
      console.log('Received deploy event, running git pull...');
      simpleGit().pull((err, update) => {
        if (err) console.error('Git pull failed:', err);
        else console.log('Git pull success:', update);
      });
    }
    listenForNotify(); // Keep listening
  });
}

listenForNotify();
