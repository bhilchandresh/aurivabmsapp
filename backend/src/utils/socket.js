const { Server } = require('socket.io');

let io;

module.exports = {
  init: (httpServer) => {
    io = new Server(httpServer, {
      cors: {
        origin: process.env.ALLOWED_ORIGINS 
          ? [...process.env.ALLOWED_ORIGINS.split(','), 'http://localhost:5173', 'http://localhost:5174']
          : ['http://localhost:5173', 'http://localhost:5174'],
        methods: ["GET", "POST", "PUT", "DELETE"],
        credentials: true
      }
    });

    io.on('connection', (socket) => {
      console.log(`[Socket.io] Client connected: ${socket.id}`);

      // When a user logs in or app initializes, they join their specific tenant room
      socket.on('join_tenant', (tenantId) => {
        if (tenantId) {
          socket.join(`tenant_${tenantId}`);
          console.log(`[Socket.io] Client ${socket.id} joined room: tenant_${tenantId}`);
        }
      });

      socket.on('disconnect', () => {
        console.log(`[Socket.io] Client disconnected: ${socket.id}`);
      });
    });

    return io;
  },
  getIO: () => {
    if (!io) {
      throw new Error('Socket.io not initialized!');
    }
    return io;
  }
};
