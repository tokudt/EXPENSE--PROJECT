const logger = require('../config/logger');

const errorHandler = (err, req, res, next) => {
    logger.error({
        message: err.message,
        stack:   err.stack,
        url:     req.url,
        method:  req.method,
        userId:  req.user?.userId,
    });

    if (res.headersSent) return next(err);

    const status  = err.status || err.statusCode || 500;
    const message = status < 500 ? err.message : 'Internal server error.';
    res.status(status).json({ error: message });
};

module.exports = { errorHandler };