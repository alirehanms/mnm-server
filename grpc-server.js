const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const knex = require('knex')(require('./knexfile').development);

// Load .proto file
const packageDef = protoLoader.loadSync('./proto/user.proto', {});
const grpcObject = grpc.loadPackageDefinition(packageDef);
const userPackage = grpcObject.UserService;

// Create gRPC server
const server = new grpc.Server();

server.addService(userPackage.service, {
  GetUser: async (call, callback) => {
    const userId = call.request.id;
    const user = await knex('users').where({ id: userId }).first();

    // ✅ Updated to match proto expectations
    callback(null, user
      ? { id: user.id, name: user.username, email: user.email }
      : { id: 0, name: '', email: '' });
  }
});

server.bindAsync('0.0.0.0:50051', grpc.ServerCredentials.createInsecure(), () => {
  console.log('gRPC server running on port 50051');
});

