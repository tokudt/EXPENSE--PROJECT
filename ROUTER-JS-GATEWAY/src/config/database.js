const sql = require('mssql');
const logger = require('../../main-router/logger');

const config = {
    server:   process.env.DB_HOST     || 'mssql',
    port:     parseInt(process.env.DB_PORT) || 1433,
    user:     process.env.DB_USER     || 'sa',
    password: process.env.DB_PASSWORD || 'YourStrong@Pass1',
    database: process.env.DB_NAME     || 'DATA_expense',
    options: {
        encrypt: true,
        trustServerCertificate: true,
        enableArithAbort: true,
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30_000,
    },
};

let poolPromise = null;

const getPool = () => {
    if (!poolPromise) {
        poolPromise = new sql.ConnectionPool(config)
            .connect()
            .then(pool => {
                logger.info('✅ Connected to MSSQL');
                return pool;
            })
            .catch(err => {
                logger.error('❌ MSSQL connection failed:', err);
                poolPromise = null;
                throw err;
            });
    }
    return poolPromise;
};

module.exports = { sql, getPool };