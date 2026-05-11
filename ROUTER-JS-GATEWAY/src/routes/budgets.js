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

// GET /api/v1/budgets → all active budgets with usage
router.get('/', async (req, res) => {
    try {
        const r = await axios.get(`${BL}/api/budgets`, { headers: fwdHeaders(req) });
        res.json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

// GET /api/v1/budgets/summary → adherence view
router.get('/summary', async (req, res) => {
    try {
        const r = await axios.get(`${BL}/api/budgets/summary`, { headers: fwdHeaders(req) });
        res.json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

// POST /api/v1/budgets → create budget
router.post('/', [
    body('name').trim().notEmpty(),
    body('budgetAmount').isFloat({ gt: 0 }),
    body('periodType').isIn(['WEEKLY','MONTHLY','QUARTERLY','YEARLY','CUSTOM']),
    body('periodStart').isISO8601(),
    body('periodEnd').isISO8601(),
    body('categoryId').optional().isInt(),
    body('alertThreshold').optional().isFloat({ min: 1, max: 100 }),
], async (req, res) => {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });

    try {
        const r = await axios.post(`${BL}/api/budgets`, req.body, { headers: fwdHeaders(req) });
        res.status(201).json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

module.exports = router;