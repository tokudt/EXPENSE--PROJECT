const express = require('express');
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');

const { sql, getPool } = require('../config/database');
const {
    generateAccessToken,
    generateRefreshToken,
    authenticateToken,
} = require('../middleware/auth');
const logger = require('../config/logger');

const router = express.Router();

// ─── POST /api/v1/auth/register ──────────────────────────────────────────────
router.post('/register', [
    body('username').trim().isLength({ min: 3, max: 100 }),
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 8 }),
    body('fullName').optional().trim(),
], async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const { username, email, password, fullName, currency = 'USD' } = req.body;

    try {
        const pool = await getPool();

        // Check duplicate
        const dup = await pool.request()
            .input('email', sql.NVarChar, email)
            .input('username', sql.NVarChar, username)
            .query('SELECT user_id FROM dbo.users WHERE email = @email OR username = @username');

        if (dup.recordset.length > 0) {
            return res.status(409).json({ error: 'Email or username already registered.' });
        }

        const passwordHash = await bcrypt.hash(password, 12);

        const result = await pool.request()
            .input('username',     sql.NVarChar, username)
            .input('email',        sql.NVarChar, email)
            .input('passwordHash', sql.NVarChar, passwordHash)
            .input('fullName',     sql.NVarChar, fullName || username)
            .input('currency',     sql.Char,     currency)
            .query(`
                INSERT INTO dbo.users (username, email, password_hash, full_name, currency)
                OUTPUT INSERTED.user_id, INSERTED.username, INSERTED.email, INSERTED.role, INSERTED.full_name
                VALUES (@username, @email, @passwordHash, @fullName, @currency)
            `);

        const user = result.recordset[0];
        const payload = { userId: user.user_id, email: user.email, role: user.role };

        logger.info(`User registered: ${email} (id=${user.user_id})`);

        res.status(201).json({
            message: 'User registered successfully.',
            accessToken:  generateAccessToken(payload),
            refreshToken: generateRefreshToken(payload),
            user,
        });
    } catch (err) { next(err); }
});

// ─── POST /api/v1/auth/login ─────────────────────────────────────────────────
router.post('/login', [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty(),
], async (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

    const { email, password } = req.body;

    try {
        const pool = await getPool();
        const r = await pool.request()
            .input('email', sql.NVarChar, email)
            .query(`
                SELECT user_id, username, email, password_hash, full_name, role, is_active
                FROM dbo.users WHERE email = @email
            `);

        const user = r.recordset[0];
        if (!user || !user.is_active) {
            return res.status(401).json({ error: 'Invalid credentials.' });
        }

        const valid = await bcrypt.compare(password, user.password_hash);
        if (!valid) {
            logger.warn(`Failed login: ${email}`);
            return res.status(401).json({ error: 'Invalid credentials.' });
        }

        await pool.request()
            .input('userId', sql.Int, user.user_id)
            .query('UPDATE dbo.users SET last_login = SYSDATETIME() WHERE user_id = @userId');

        const payload = { userId: user.user_id, email: user.email, role: user.role };

        logger.info(`User logged in: ${email}`);

        res.json({
            accessToken:  generateAccessToken(payload),
            refreshToken: generateRefreshToken(payload),
            user: {
                userId:   user.user_id,
                username: user.username,
                email:    user.email,
                fullName: user.full_name,
                role:     user.role,
            },
        });
    } catch (err) { next(err); }
});

// ─── POST /api/v1/auth/refresh ───────────────────────────────────────────────
router.post('/refresh', (req, res) => {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(401).json({ error: 'Refresh token required.' });

    try {
        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        const payload = { userId: decoded.userId, email: decoded.email, role: decoded.role };
        res.json({ accessToken: generateAccessToken(payload) });
    } catch {
        res.status(403).json({ error: 'Invalid or expired refresh token.' });
    }
});

// ─── POST /api/v1/auth/logout ────────────────────────────────────────────────
router.post('/logout', authenticateToken, (req, res) => {
    logger.info(`User logged out: ${req.user.email}`);
    res.json({ message: 'Logged out.' });
});

module.exports = router;