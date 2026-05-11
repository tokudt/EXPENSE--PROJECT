const express = require('express');
const axios   = require('axios');
const { body, query, param, validationResult } = require('express-validator');

const logger = require('../config/logger');

const router = express.Router();

const BL = process.env.BUSINESS_LOGIC_URL || 'http://business-logic:5000';
const ML = process.env.ML_SERVICE_URL     || 'http://ml-service:8000';
const GW_SECRET = process.env.GATEWAY_SECRET || 'change-me';

const fwdHeaders = (req) => ({
    'X-User-Id':       String(req.user.userId),
    'X-User-Role':     req.user.role,
    'X-Gateway-Secret': GW_SECRET,
    'Content-Type':    'application/json',
});

// ─── GET /api/v1/transactions ─────────────────────────────────────────────────
router.get('/', [
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('categoryId').optional().isInt(),
    query('startDate').optional().isISO8601(),
    query('endDate').optional().isISO8601(),
    query('transactionType').optional().isIn(['EXPENSE','INCOME','TRANSFER','REFUND','INVESTMENT']),
], async (req, res, next) => {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });

    try {
        const r = await axios.get(`${BL}/api/transactions`, {
            headers: fwdHeaders(req),
            params:  req.query,
        });
        res.json(r.data);
    } catch (err) {
        logger.error('GET /transactions failed:', err.message);
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

// ─── GET /api/v1/transactions/:id ────────────────────────────────────────────
router.get('/:id', param('id').isInt(), async (req, res) => {
    try {
        const r = await axios.get(`${BL}/api/transactions/${req.params.id}`, { headers: fwdHeaders(req) });
        res.json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

// ─── POST /api/v1/transactions ───────────────────────────────────────────────
// Orchestrates: BL validate → ML analyze → BL persist
router.post('/', [
    body('accountId').isInt(),
    body('categoryId').optional().isInt(),
    body('amount').isFloat({ gt: 0 }),
    body('transactionType').isIn(['EXPENSE','INCOME','TRANSFER','REFUND','INVESTMENT']),
    body('transactionDate').isISO8601(),
    body('description').optional().isString(),
    body('merchant').optional().isString(),
    body('currency').optional().isString().isLength({ min: 3, max: 5 }),
], async (req, res) => {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });

    try {
        // 1) Business validation (budgets, limits, rules)
        const validate = await axios.post(`${BL}/api/transactions/validate`, req.body, {
            headers: fwdHeaders(req),
        });

        if (!validate.data.isValid) {
            return res.status(422).json({
                error:      'Transaction validation failed.',
                violations: validate.data.violations,
            });
        }

        // 2) ML analysis (non-blocking; bounded timeout)
        let mlResult = { anomaly: false, anomalyScore: 0, predictions: [], insights: [] };
        try {
            const mlRes = await axios.post(`${ML}/analyze`, {
                userId:     req.user.userId,
                expense:    req.body,
                historical: validate.data.historicalContext,
            }, { timeout: 3000 });
            mlResult = mlRes.data;
        } catch (mlErr) {
            logger.warn(`ML analyze unavailable: ${mlErr.message}`);
        }

        // 3) Persist via BL (with ML flags)
        const create = await axios.post(`${BL}/api/transactions`, {
            ...req.body,
            mlFlags: mlResult,
        }, { headers: fwdHeaders(req) });

        res.status(201).json({
            transaction: create.data,
            insights:    mlResult,
        });
    } catch (err) {
        logger.error('POST /transactions error:', err.message);
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

// ─── PUT /api/v1/transactions/:id ────────────────────────────────────────────
router.put('/:id', [
    param('id').isInt(),
    body('amount').optional().isFloat({ gt: 0 }),
    body('description').optional().isString(),
    body('categoryId').optional().isInt(),
], async (req, res) => {
    const errs = validationResult(req);
    if (!errs.isEmpty()) return res.status(400).json({ errors: errs.array() });

    try {
        const r = await axios.put(`${BL}/api/transactions/${req.params.id}`, req.body, {
            headers: fwdHeaders(req),
        });
        res.json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

// ─── DELETE /api/v1/transactions/:id ─────────────────────────────────────────
router.delete('/:id', param('id').isInt(), async (req, res) => {
    try {
        const r = await axios.delete(`${BL}/api/transactions/${req.params.id}`, { headers: fwdHeaders(req) });
        res.json(r.data);
    } catch (err) {
        res.status(err.response?.status || 502).json(err.response?.data || { error: 'Service unavailable.' });
    }
});

module.exports = router;