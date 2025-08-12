const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');

const packageDef = protoLoader.loadSync('./stream-example.proto');
const grpcObject = grpc.loadPackageDefinition(packageDef);
const streamService = grpcObject.StreamService;

const server = new grpc.Server();

server.addService(streamService.service, {
  UnaryCall: (call, callback) => {
    console.log('UnaryCall received:', call.request.text);
    callback(null, { text: `Hello from server: ${call.request.text}` });
  },

  ServerStream: (call) => {
    console.log('ServerStream received:', call.request.text);
    for (let i = 1; i <= 5; i++) {
      call.write({ text: `Message ${i} from server` });
    }
    call.end();
  },

  ClientStream: (call, callback) => {
    let allMessages = [];
    call.on('data', (msg) => {
      console.log('Client sent:', msg.text);
      allMessages.push(msg.text);
    });

    call.on('end', () => {
      callback(null, { text: `Received: ${allMessages.join(', ')}` });
    });
  },

  BiDiStream: (call) => {
    call.on('data', (msg) => {
      console.log('Client:', msg.text);
      call.write({ text: `Echo: ${msg.text}` });
    });

    call.on('end', () => {
      call.end();
    });
  }
});

server.bindAsync('0.0.0.0:50052', grpc.ServerCredentials.createInsecure(), () => {
  console.log('gRPC Stream Server running on port 50052');
  server.start();
});
