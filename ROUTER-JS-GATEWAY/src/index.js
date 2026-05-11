require('dotenv').config();
const express       = require('express');
const helmet        = require('helmet');
const cors          = require('cors');
const morgan        = require('morgan');
const rateLimit     = require('express-rate-limit');

const authRoutes    = require ('./routes/auth');
const transactionRoutes = require('./routes/transactions');
const accountRoutes = require('./routes/accounts');
const categoryRoutes = require('./routes/categories');
const budgetRoutes = require('./routes/budgets');
const analyticsRoutes = require('./routes/analytics');

const { authenticateToken } = require('./middleware/auth');
const { errorHandler } = require('./middleware/ErrorHandler');

const logger = require('./config/logger');

const app = express();
const PORT = process.env.PORT || 3000;

// security
app.use(helmet());
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS.split(',') || ['http://localhost:3000', 'http://localhost:5173'],
    credentials: true,
}));

// Rate limits

app.use(rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 200,
    standardHeaders: true,
    message: { error: 'Too many requests, please try again later.' },
}));

const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 10
});

// body / logging

app.use(express.json({limit: '10mb'}));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined', {stream: {write: m => logger.info(m.trim())}}));

// Health check
app.get('/health', (_, res) => res.json({
    status: 'healthy',
    service: 'api-gateway',
    timestamp: new Date().toISOString(),
}));

// public

app.use('/api/auth', authLimiter, authRoutes);

// protected
app.use('/api/v1/transactions', authenticateToken, transactionRoutes);
app.use('/api/v1/accounts',     authenticateToken, accountRoutes);
app.use('/api/v1/categories',   authenticateToken, categoryRoutes);
app.use('/api/v1/budgets',      authenticateToken, budgetRoutes);
app.use('/api/v1/analytics',    authenticateToken, analyticsRoutes);

app.use(errorHandler);

app.listen(PORT, () => logger.info(`🚀 Gateway running on port ${PORT}`));

module.exports = app;