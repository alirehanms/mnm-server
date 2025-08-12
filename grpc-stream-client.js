const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');

const packageDef = protoLoader.loadSync('./stream-example.proto');
const grpcObject = grpc.loadPackageDefinition(packageDef);
const StreamService = grpcObject.StreamService;

const client = new StreamService('localhost:50052', grpc.credentials.createInsecure());

// Unary Call
client.UnaryCall({ text: 'Unary Test' }, (err, res) => {
  console.log('Unary Response:', res.text);
});

// Server Stream
const serverStream = client.ServerStream({ text: 'Start streaming' });
serverStream.on('data', (msg) => console.log('Server Stream:', msg.text));
serverStream.on('end', () => console.log('Server stream ended'));

// Client Stream
const clientStream = client.ClientStream((err, res) => {
  if (err) return console.error(err);
  console.log('Client Stream response:', res.text);
});
['One', 'Two', 'Three'].forEach(text => clientStream.write({ text }));
clientStream.end();

// BiDi Stream
const bidi = client.BiDiStream();
['A', 'B', 'C'].forEach(text => bidi.write({ text }));
bidi.on('data', (msg) => console.log('BiDi Stream:', msg.text));
bidi.on('end', () => console.log('BiDi stream ended'));
bidi.end();
