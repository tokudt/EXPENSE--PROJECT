const express = require('express');
const axios   = require('axios');
const { body, param, validationResult } = require('express-validator');

const router = express.Router();

const BL = process.env.BUSINESS_LOGIC_URL || 'http://business-logic:5000';
const GW_SECRET = process.env.GATEWAY_SECRET || 'change-me';

const fwdHeaders = (req) => ({
    'X-User-Id':        String(req.user.userId),
    'X-User-Role':      req.user.role,
    'X-Gateway-Secret': GW_SECRET,
});

// GET /api/v1/accounts → list user's accounts
router.get('/', async (req, res) => {
    try {
        const r = await axios.get(`${BL}/api/accounts`, { headers: fwdHeaders(req) });
        res.json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

// POST /api/v1/accounts → create new account
router.post('/', [
    body('name').notEmpty(),
    body('accountType').isIn(['CHECKING','SAVING','CREDIT_CARD','CASH','INVESTMENT','LOAN']),
    body('balance').optional().isFloat({ min: 0 }),
    body('currency').optional().isString().isLength({ min: 3, max: 5 }),
], async (req, res) => {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });

    try {
        const r = await axios.post(`${BL}/api/accounts`, req.body, { headers: fwdHeaders(req) });
        res.status(201).json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

// GET /api/v1/accounts/:id
router.get('/:id', param('id').isInt(), async (req, res) => {
    try {
        const r = await axios.get(`${BL}/api/accounts/${req.params.id}`, { headers: fwdHeaders(req) });
        res.json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

module.exports = router;