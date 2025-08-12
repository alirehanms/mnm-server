const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');

// Load the same .proto file used by the server
const packageDef = protoLoader.loadSync('./proto/user.proto', {});
const grpcObject = grpc.loadPackageDefinition(packageDef);
const userPackage = grpcObject.UserService;

// Create a client connected to the gRPC server at localhost:50051
const client = new userPackage('localhost:50051', grpc.credentials.createInsecure());

// Call the GetUser method
const userIdToFetch = 1; // change this to test other user ids

client.GetUser({ id: userIdToFetch }, (error, response) => {
  if (error) {
    console.error('Error from gRPC:', error);
  } else {
    console.log('User data:', response);
  }
});
