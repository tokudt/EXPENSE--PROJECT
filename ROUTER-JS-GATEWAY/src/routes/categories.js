const express = require('express');
const axios   = require('axios');
const { body, validationResult } = require('express-validator');

const router = express.Router();
const BL = process.env.BUSINESS_LOGIC_URL || 'http://business-logic:5000';
const GW_SECRET = process.env.GATEWAY_SECRET || 'change-me';

const fwdHeaders = (req) => ({
    'X-User-Id':        String(req.user.userId),
    'X-User-Role':      req.user.role,
    'X-Gateway-Secret': GW_SECRET,
});

// GET /api/v1/categories → user-specific + system categories
router.get('/', async (req, res) => {
    try {
        const r = await axios.get(`${BL}/api/categories`, { headers: fwdHeaders(req) });
        res.json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

// POST /api/v1/categories → create user category
router.post('/', [
    body('name').trim().notEmpty(),
    body('expenseType').isIn(['fixed','variable','semi_variable']),
    body('parentId').optional().isInt(),
], async (req, res) => {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });

    try {
        const r = await axios.post(`${BL}/api/categories`, req.body, { headers: fwdHeaders(req) });
        res.status(201).json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

module.exports = router;