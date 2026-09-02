require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const mongoSanitize = require('express-mongo-sanitize');
const rateLimit = require('express-rate-limit');
const dns = require('dns'); // 🔴 DNS Fix for EREFUSED
dns.setServers(['8.8.8.8', '8.8.4.4']);


// --- 1. Import Route Files ---
const authRoutes = require('./routes/authRoutes');
const invoiceRoutes = require('./routes/invoiceRoutes');
const clientRoutes = require('./routes/clientRoutes');
const quotationRoutes = require('./routes/quotationRoutes');
const businessRoutes = require('./routes/businessRoutes');
const userRoutes = require('./routes/userRoutes');
const inventoryRoutes = require('./routes/inventoryRoutes');
const supplierRoutes = require('./routes/supplierRoutes');
const employeeRoutes = require('./routes/employeeRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const settingsRoutes = require('./routes/settingsRoutes');
const publicRoutes = require('./routes/publicRoutes');
const securityRoutes = require('./routes/securityRoutes');
const webhookRoutes = require('./routes/webhookRoutes');
const ipBlocker = require('./middleware/ipBlocker');
const { trafficMonitor } = require('./middleware/trafficMonitor');
const BlockedIP = require('./models/BlockedIP');
const app = express();
app.set('trust proxy', 1);

// --- 2. Middleware ---
app.use(ipBlocker); // Apply IP blocker globally before any routes
app.use(trafficMonitor); // Track live IP traffic
app.use(helmet());
app.use(compression());
app.use(morgan('dev')); // Structured HTTP Logging
app.use(mongoSanitize()); // Prevent NoSQL injection

// Body Parser Limits (Sirf ek baar likhna kaafi hai)
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// CORS Configuration
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? [...process.env.ALLOWED_ORIGINS.split(','), 'http://localhost:5174']
  : ['http://localhost:5173', 'http://localhost:5174'];

app.use(cors({
  origin: function (origin, callback) {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    if (allowedOrigins.indexOf(origin) === -1) {
      console.warn(`CORS blocked for origin: ${origin}`);
      return callback(new Error('Not allowed by CORS'), false);
    }
    return callback(null, true);
  },
  credentials: true
}));

// Rate Limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 2000, // 🔴 Thoda badha diya taaki heavy use me block na ho
  standardHeaders: true,
  legacyHeaders: false,
  message: "Too many requests, please try again after 15 minutes.",
  handler: async (req, res, next, options) => {
    try {
      const clientIp = req.headers['x-forwarded-for'] || req.connection.remoteAddress || req.socket.remoteAddress || req.ip;
      const cleanIp = clientIp.includes('::ffff:') ? clientIp.split('::ffff:')[1] : clientIp;
      
      // Save to database as auto-blocked
      await BlockedIP.updateOne(
        { ipAddress: cleanIp }, 
        { 
          $set: { 
            ipAddress: cleanIp, 
            reason: 'Auto-blocked by Rate Limiter (Exceeded 500 req/15min)',
            autoBlocked: true,
            expiresAt: new Date(Date.now() + 15 * 60 * 1000)
          } 
        }, 
        { upsert: true }
      );
    } catch (err) {
      console.error('Rate Limiter Auto-Block Log Error:', err);
    }
    res.status(options.statusCode).send(options.message);
  }
});
app.use('/api', limiter);

// --- 3. Mount Routes ---
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/invoices', invoiceRoutes);
app.use('/api/v1/clients', clientRoutes);
app.use('/api/v1/quotations', quotationRoutes);
app.use('/api/v1/business', businessRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/inventory', inventoryRoutes);
app.use('/api/v1/suppliers', supplierRoutes);
app.use('/api/v1/employees', employeeRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/settings', settingsRoutes);
app.use('/api/v1/public', publicRoutes);
app.use('/api/v1/security', securityRoutes);
app.use('/api/v1/webhooks', webhookRoutes);
// --- 4. Base Route ---
app.get('/', (req, res) => {
  res.send('AurivaBMS API is running securely...');
});

// --- 5. Global Error Handler ---
app.use((err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  // Log error for internal monitoring
  console.error(`[ERROR] ${req.method} ${req.url} - ${statusCode}: ${message}`);
  if (process.env.NODE_ENV !== 'production') console.error(err.stack);

  res.status(statusCode).json({
    success: false,
    message: message,
    // stack: process.env.NODE_ENV === 'production' ? null : err.stack
  });
});

// --- 6. Database & Server ---
const connectDB = async () => {
  try {
    // 🔴 Added options for better connection stability and high load
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      serverSelectionTimeoutMS: 30000,
      socketTimeoutMS: 45000,
      maxPoolSize: 500
    });
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`DB Connection Error: ${error.message}`);
    process.exit(1);
  }
};

const http = require('http');
const socketIO = require('./utils/socket');

const PORT = process.env.PORT || 5001;
const server = http.createServer(app);

// Initialize Socket.io
socketIO.init(server);

connectDB().then(() => {
  // Initialize Cron Jobs
  const cronService = require('./services/cronService');
  cronService.initCronJobs();

  server.listen(PORT, () => {
    console.log(`Server running securely on port ${PORT}`);
  });
});