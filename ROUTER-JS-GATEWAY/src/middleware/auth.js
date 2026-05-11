const jwt = require('jsonwebtoken');
const logger = require('../config/logger');

const authenticateToken = (req, res, next) => {
    const header = req.headers['authorization'];
    const token  = header?.startsWith('Bearer ') ? header.slice(7) : null;

    if (!token) return res.status(401).json({ error: 'Access token required.' });

    try {
        req.user = jwt.verify(token, process.env.JWT_SECRET);
        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({ error: 'Token expired.' });
        }
        logger.warn(`Invalid token from ${req.ip}`);
        return res.status(403).json({ error: 'Invalid token.' });
    }
};

const authorize = (...roles) => (req, res, next) => {
    if (!req.user) return res.status(401).json({ error: 'Auth required.' });
    if (!roles.includes(req.user.role)) {
        return res.status(403).json({ error: 'Insufficient permissions.' });
    }
    next();
};

const generateAccessToken  = p => jwt.sign(p, process.env.JWT_SECRET,         { expiresIn: '15m' });
const generateRefreshToken = p => jwt.sign(p, process.env.JWT_REFRESH_SECRET, { expiresIn: '7d'  });

module.exports = { authenticateToken, authorize, generateAccessToken, generateRefreshToken };