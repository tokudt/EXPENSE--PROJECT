const express = require('express');
const axios   = require('axios');
const { query, validationResult } = require('express-validator');
const logger = require('../config/logger');

const router = express.Router();
const BL = process.env.BUSINESS_LOGIC_URL || 'http://business-logic:5000';
const ML = process.env.ML_SERVICE_URL     || 'http://ml-service:8000';
const GW_SECRET = process.env.GATEWAY_SECRET || 'change-me';

const fwdHeaders = (req) => ({
    'X-User-Id':        String(req.user.userId),
    'X-User-Role':      req.user.role,
    'X-Gateway-Secret': GW_SECRET,
});

// GET /api/v1/analytics/predictions?months=3
router.get('/predictions', [
    query('months').optional().isInt({ min: 1, max: 12 }),
], async (req, res) => {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });

    try {
        // 1) Pull history from BL
        const history = await axios.get(`${BL}/api/transactions/history`, {
            headers: fwdHeaders(req),
            params:  { months: req.query.months || 6 },
        });

        // 2) Send to ML for prediction
        const ml = await axios.post(`${ML}/predict`, {
            userId:         req.user.userId,
            history:        history.data.transactions,
            forecastMonths: parseInt(req.query.months) || 3,
        });

        res.json(ml.data);
    } catch (err) {
        logger.error('GET /analytics/predictions failed:', err.message);
        res.status(err.response?.status || 502).json({ error: 'Analytics unavailable.' });
    }
});

// GET /api/v1/analytics/anomalies
router.get('/anomalies', async (req, res) => {
    try {
        const history = await axios.get(`${BL}/api/transactions/history`, {
            headers: fwdHeaders(req),
            params:  { months: 6 },
        });

        const ml = await axios.post(`${ML}/detect-anomalies`, {
            userId:   req.user.userId,
            expenses: history.data.transactions,
        });

        res.json(ml.data);
    } catch (err) {
        logger.error('GET /analytics/anomalies failed:', err.message);
        res.status(err.response?.status || 502).json({ error: 'Analytics unavailable.' });
    }
});

// GET /api/v1/analytics/insights
router.get('/insights', async (req, res) => {
    try {
        const [history, budgets] = await Promise.all([
            axios.get(`${BL}/api/transactions/history`, {
                headers: fwdHeaders(req), params: { months: 3 },
            }),
            axios.get(`${BL}/api/budgets/summary`, { headers: fwdHeaders(req) }),
        ]);

        const ml = await axios.post(`${ML}/insights`, {
            userId:  req.user.userId,
            history: history.data.transactions,
            budgets: budgets.data.budgets,
        });

        res.json(ml.data);
    } catch (err) {
        logger.error('GET /analytics/insights failed:', err.message);
        res.status(err.response?.status || 502).json({ error: 'Analytics unavailable.' });
    }
});

// GET /api/v1/analytics/summary?period=month
router.get('/summary', [
    query('period').optional().isIn(['week','month','quarter','year']),
], async (req, res) => {
    try {
        const r = await axios.get(`${BL}/api/analytics/summary`, {
            headers: fwdHeaders(req), params: req.query,
        });
        res.json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json({ error: 'Service unavailable.' });
    }
});

module.exports = router;