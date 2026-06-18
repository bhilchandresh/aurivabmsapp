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
const notificationRoutes = require('./routes/notificationRoutes');
const paymentRoutes = require('./routes/paymentRoutes');

const app = express();

// --- 2. Middleware ---
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
  max: 500, // 🔴 Thoda badha diya taaki heavy use me block na ho
  standardHeaders: true,
  legacyHeaders: false,
  message: "Too many requests, please try again after 15 minutes."
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
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/payments', paymentRoutes);

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
    // 🔴 Added options for better connection stability
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      serverSelectionTimeoutMS: 5000
    });
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`DB Connection Error: ${error.message}`);
    process.exit(1);
  }
};

const PORT = process.env.PORT || 5001;

connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`Server running securely on port ${PORT}`);
  });
});