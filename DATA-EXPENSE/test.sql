-- ============================================================
--  PERSONAL FINANCE DATABASE
--  Supports: Expense Analysis, Behavior & Insights,
--            Financial Health & Predictive Analytics
-- ============================================================

-- ============================================================
-- SECTION 1: CORE REFERENCE TABLES
-- ============================================================

CREATE TABLE users (
    user_id         SERIAL PRIMARY KEY,
    username        VARCHAR(100) NOT NULL UNIQUE,
    email           VARCHAR(255) NOT NULL UNIQUE,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    monthly_income  NUMERIC(14,2),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────
-- Categories: hierarchical (parent → child)
-- expense_type: FIXED | VARIABLE | SEMI_VARIABLE
-- ──────────────────────────────────────────────────────────
CREATE TABLE categories (
    category_id     SERIAL PRIMARY KEY,
    user_id         INT REFERENCES users(user_id) ON DELETE CASCADE,
    parent_id       INT REFERENCES categories(category_id),
    name            VARCHAR(100) NOT NULL,
    icon            VARCHAR(50),
    color           CHAR(7),                          -- hex color
    expense_type    VARCHAR(20) NOT NULL DEFAULT 'VARIABLE'
                        CHECK (expense_type IN ('FIXED','VARIABLE','SEMI_VARIABLE')),
    is_system       BOOLEAN NOT NULL DEFAULT FALSE,   -- built-in vs user-defined
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed: system-level categories
INSERT INTO categories (user_id, parent_id, name, expense_type, is_system) VALUES
(NULL, NULL, 'Housing',           'FIXED',        TRUE),
(NULL, NULL, 'Food & Dining',     'VARIABLE',     TRUE),
(NULL, NULL, 'Transport',         'SEMI_VARIABLE', TRUE),
(NULL, NULL, 'Health',            'VARIABLE',     TRUE),
(NULL, NULL, 'Entertainment',     'VARIABLE',     TRUE),
(NULL, NULL, 'Shopping',          'VARIABLE',     TRUE),
(NULL, NULL, 'Utilities',         'SEMI_VARIABLE', TRUE),
(NULL, NULL, 'Education',         'FIXED',        TRUE),
(NULL, NULL, 'Personal Care',     'VARIABLE',     TRUE),
(NULL, NULL, 'Savings',           'FIXED',        TRUE),
(NULL, NULL, 'Income',            'VARIABLE',     TRUE);

-- ──────────────────────────────────────────────────────────
-- Accounts: bank accounts, wallets, cards
-- ──────────────────────────────────────────────────────────
CREATE TABLE accounts (
    account_id      SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    account_type    VARCHAR(30) NOT NULL
                        CHECK (account_type IN ('CHECKING','SAVINGS','CREDIT_CARD',
                                                'CASH','INVESTMENT','LOAN')),
    balance         NUMERIC(14,2) NOT NULL DEFAULT 0,
    credit_limit    NUMERIC(14,2),                    -- for credit cards
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    institution     VARCHAR(100),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────
-- Tags: flexible labeling (e.g. "business", "recurring")
-- ──────────────────────────────────────────────────────────
CREATE TABLE tags (
    tag_id      SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    name        VARCHAR(50) NOT NULL,
    UNIQUE (user_id, name)
);

-- ============================================================
-- SECTION 2: TRANSACTIONS
-- ============================================================

CREATE TABLE transactions (
    transaction_id      SERIAL PRIMARY KEY,
    user_id             INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    account_id          INT NOT NULL REFERENCES accounts(account_id),
    category_id         INT REFERENCES categories(category_id),

    -- Core amounts
    amount              NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    currency            CHAR(3) NOT NULL DEFAULT 'USD',
    amount_base_currency NUMERIC(14,2),               -- normalized for FX
    exchange_rate       NUMERIC(12,6) DEFAULT 1.0,

    -- Direction & type
    transaction_type    VARCHAR(20) NOT NULL
                            CHECK (transaction_type IN ('EXPENSE','INCOME',
                                                        'TRANSFER','REFUND',
                                                        'INVESTMENT')),
    is_recurring        BOOLEAN NOT NULL DEFAULT FALSE,
    recurrence_id       INT,                          -- FK set later

    -- Metadata
    merchant            VARCHAR(255),
    description         TEXT,
    notes               TEXT,
    transaction_date    DATE NOT NULL,
    posted_date         DATE,

    -- Location (optional, for geo-analytics)
    latitude            NUMERIC(9,6),
    longitude           NUMERIC(9,6),
    city                VARCHAR(100),
    country             CHAR(2),

    -- Flags
    is_verified         BOOLEAN NOT NULL DEFAULT FALSE,
    is_excluded         BOOLEAN NOT NULL DEFAULT FALSE, -- exclude from analytics
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Many-to-many: transactions ↔ tags
CREATE TABLE transaction_tags (
    transaction_id  INT NOT NULL REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    tag_id          INT NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (transaction_id, tag_id)
);

-- ──────────────────────────────────────────────────────────
-- Recurring rules (subscriptions, rent, salary, etc.)
-- ──────────────────────────────────────────────────────────
CREATE TABLE recurring_rules (
    recurrence_id       SERIAL PRIMARY KEY,
    user_id             INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    account_id          INT NOT NULL REFERENCES accounts(account_id),
    category_id         INT REFERENCES categories(category_id),
    transaction_type    VARCHAR(20) NOT NULL,
    amount              NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    description         VARCHAR(255),
    frequency           VARCHAR(20) NOT NULL
                            CHECK (frequency IN ('DAILY','WEEKLY','BIWEEKLY',
                                                 'MONTHLY','QUARTERLY','YEARLY')),
    start_date          DATE NOT NULL,
    end_date            DATE,
    last_generated_date DATE,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Back-fill FK
ALTER TABLE transactions
    ADD CONSTRAINT fk_recurrence
    FOREIGN KEY (recurrence_id)
    REFERENCES recurring_rules(recurrence_id);

-- ============================================================
-- SECTION 3: BUDGETS
-- ============================================================

CREATE TABLE budgets (
    budget_id       SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    category_id     INT REFERENCES categories(category_id),
    name            VARCHAR(100) NOT NULL,

    -- Period
    period_type     VARCHAR(10) NOT NULL DEFAULT 'MONTHLY'
                        CHECK (period_type IN ('WEEKLY','MONTHLY','QUARTERLY','YEARLY','CUSTOM')),
    period_start    DATE NOT NULL,
    period_end      DATE NOT NULL,

    -- Amounts
    budgeted_amount NUMERIC(14,2) NOT NULL CHECK (budgeted_amount >= 0),
    rollover        BOOLEAN NOT NULL DEFAULT FALSE,   -- carry unspent to next period
    alert_threshold NUMERIC(5,2) DEFAULT 80.0,        -- alert at X% spent
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SECTION 4: ANALYTICS SUPPORT TABLES
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- Daily aggregates — pre-computed for speed
-- (populated by trigger or scheduled job)
-- ──────────────────────────────────────────────────────────
CREATE TABLE daily_summaries (
    summary_id      SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    summary_date    DATE NOT NULL,
    total_expenses  NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_income    NUMERIC(14,2) NOT NULL DEFAULT 0,
    net_flow        NUMERIC(14,2) GENERATED ALWAYS AS (total_income - total_expenses) STORED,
    transaction_count INT NOT NULL DEFAULT 0,
    UNIQUE (user_id, summary_date)
);

-- ──────────────────────────────────────────────────────────
-- Monthly category totals — for trend & anomaly queries
-- ──────────────────────────────────────────────────────────
CREATE TABLE monthly_category_totals (
    id              SERIAL PRIMARY KEY,
    user_id         INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    category_id     INT NOT NULL REFERENCES categories(category_id),
    year            SMALLINT NOT NULL,
    month           SMALLINT NOT NULL CHECK (month BETWEEN 1 AND 12),
    total_amount    NUMERIC(14,2) NOT NULL DEFAULT 0,
    transaction_count INT NOT NULL DEFAULT 0,
    avg_transaction NUMERIC(14,2),
    UNIQUE (user_id, category_id, year, month)
);

-- ──────────────────────────────────────────────────────────
-- Spending scores & health snapshots
-- (one row per user per month)
-- ──────────────────────────────────────────────────────────
CREATE TABLE financial_snapshots (
    snapshot_id             SERIAL PRIMARY KEY,
    user_id                 INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    year                    SMALLINT NOT NULL,
    month                   SMALLINT NOT NULL CHECK (month BETWEEN 1 AND 12),

    -- Expense Analysis
    total_expenses          NUMERIC(14,2),
    total_income            NUMERIC(14,2),
    net_savings             NUMERIC(14,2),
    savings_rate_pct        NUMERIC(6,3),             -- net_savings / income * 100
    fixed_expense_total     NUMERIC(14,2),
    variable_expense_total  NUMERIC(14,2),

    -- Behavior & Insight
    budget_adherence_pct    NUMERIC(6,3),             -- % of budgets not exceeded
    overspent_categories    JSONB,                     -- [{category, budgeted, actual}]
    anomaly_flags           JSONB,                     -- [{category, score, reason}]
    spending_consistency_score NUMERIC(5,2),          -- 0–100

    -- Financial Health
    burn_rate               NUMERIC(14,2),             -- avg daily expense
    predicted_next_month    NUMERIC(14,2),             -- model output
    months_of_runway        NUMERIC(6,2),              -- savings / burn_rate

    computed_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, year, month)
);

-- ──────────────────────────────────────────────────────────
-- Anomaly log — detected individually
-- ──────────────────────────────────────────────────────────
CREATE TABLE anomalies (
    anomaly_id          SERIAL PRIMARY KEY,
    user_id             INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    transaction_id      INT REFERENCES transactions(transaction_id),
    category_id         INT REFERENCES categories(category_id),
    anomaly_type        VARCHAR(50) NOT NULL
                            CHECK (anomaly_type IN (
                                'OVERSPEND','UNUSUAL_MERCHANT','LARGE_TRANSACTION',
                                'FREQUENCY_SPIKE','CATEGORY_GROWTH','BUDGET_BREACH'
                            )),
    severity            VARCHAR(10) NOT NULL DEFAULT 'MEDIUM'
                            CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    description         TEXT,
    detected_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    acknowledged_at     TIMESTAMPTZ,
    is_false_positive   BOOLEAN NOT NULL DEFAULT FALSE
);

-- ──────────────────────────────────────────────────────────
-- Expense predictions (ML / statistical outputs)
-- ──────────────────────────────────────────────────────────
CREATE TABLE expense_predictions (
    prediction_id       SERIAL PRIMARY KEY,
    user_id             INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    category_id         INT REFERENCES categories(category_id),
    target_year         SMALLINT NOT NULL,
    target_month        SMALLINT NOT NULL CHECK (target_month BETWEEN 1 AND 12),
    predicted_amount    NUMERIC(14,2) NOT NULL,
    confidence_lower    NUMERIC(14,2),
    confidence_upper    NUMERIC(14,2),
    model_name          VARCHAR(50),                   -- e.g. 'linear_regression'
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, category_id, target_year, target_month)
);

-- ============================================================
-- SECTION 5: INDEXES FOR ANALYTICS PERFORMANCE
-- ============================================================

-- Hot path: all user expenses in a date range
CREATE INDEX idx_txn_user_date
    ON transactions (user_id, transaction_date DESC);

-- Category drill-down
CREATE INDEX idx_txn_user_category
    ON transactions (user_id, category_id, transaction_date DESC);

-- Monthly category roll-ups
CREATE INDEX idx_mct_user_period
    ON monthly_category_totals (user_id, year DESC, month DESC);

-- Anomaly lookups
CREATE INDEX idx_anomaly_user
    ON anomalies (user_id, detected_at DESC);

-- Recurring transactions
CREATE INDEX idx_txn_recurrence
    ON transactions (recurrence_id)
    WHERE recurrence_id IS NOT NULL;

-- Budget period lookup
CREATE INDEX idx_budget_user_period
    ON budgets (user_id, period_start, period_end);

-- ============================================================
-- SECTION 6: VIEWS (pre-built insight queries)
-- ============================================================

-- ── WHERE IS MONEY GOING? (current month) ──────────────────
DROP VIEW IF EXISTS vw_current_month_by_category;
GO
CREATE VIEW vw_current_month_by_category AS
SELECT
    t.user_id,
    c.name                              AS category,
    c.expense_type,
    SUM(t.amount)                       AS total_spent,
    COUNT(*)                            AS txn_count,
    ROUND(AVG(t.amount), 2)             AS avg_per_txn
FROM transactions t
JOIN categories c ON c.category_id = t.category_id
WHERE t.transaction_type = 'EXPENSE'
  AND t.is_excluded = 0
  AND DATEPART(YEAR, t.transaction_date) = DATEPART(YEAR, GETDATE())
  AND DATEPART(MONTH, t.transaction_date) = DATEPART(MONTH, GETDATE())
GROUP BY t.user_id, c.name, c.expense_type;

-- ── CATEGORY GROWTH (MoM %) ────────────────────────────────
CREATE OR REPLACE VIEW vw_category_growth_mom AS
SELECT
    cur.user_id,
    cur.category_id,
    c.name                                          AS category,
    cur.year,
    cur.month,
    cur.total_amount                                AS current_amount,
    prev.total_amount                               AS prev_amount,
    CASE WHEN prev.total_amount > 0
         THEN ROUND(((cur.total_amount - prev.total_amount)
                     / prev.total_amount) * 100, 2)
         ELSE NULL
    END                                             AS growth_pct
FROM monthly_category_totals cur
LEFT JOIN monthly_category_totals prev
       ON prev.user_id     = cur.user_id
      AND prev.category_id = cur.category_id
      AND (prev.year * 12 + prev.month) = (cur.year * 12 + cur.month) - 1
JOIN categories c ON c.category_id = cur.category_id;

-- ── FIXED vs VARIABLE SPLIT ────────────────────────────────
CREATE OR REPLACE VIEW vw_fixed_variable_split AS
SELECT
    t.user_id,
    DATE_TRUNC('month', t.transaction_date)         AS month,
    SUM(CASE WHEN c.expense_type = 'FIXED'    THEN t.amount ELSE 0 END) AS fixed_total,
    SUM(CASE WHEN c.expense_type = 'VARIABLE' THEN t.amount ELSE 0 END) AS variable_total,
    SUM(CASE WHEN c.expense_type = 'SEMI_VARIABLE' THEN t.amount ELSE 0 END) AS semi_variable_total,
    SUM(t.amount) AS grand_total
FROM transactions t
JOIN categories c ON c.category_id = t.category_id
WHERE t.transaction_type = 'EXPENSE'
  AND t.is_excluded = FALSE
GROUP BY t.user_id, DATE_TRUNC('month', t.transaction_date);

-- ── BUDGET ADHERENCE ───────────────────────────────────────
CREATE OR REPLACE VIEW vw_budget_adherence AS
SELECT
    b.user_id,
    b.budget_id,
    b.name                                              AS budget_name,
    c.name                                              AS category,
    b.budgeted_amount,
    COALESCE(SUM(t.amount), 0)                          AS spent_amount,
    b.budgeted_amount - COALESCE(SUM(t.amount), 0)      AS remaining,
    ROUND(COALESCE(SUM(t.amount), 0)
          / NULLIF(b.budgeted_amount, 0) * 100, 2)      AS pct_used,
    CASE WHEN COALESCE(SUM(t.amount), 0) > b.budgeted_amount
         THEN TRUE ELSE FALSE END                        AS is_overspent
FROM budgets b
LEFT JOIN categories c ON c.category_id = b.category_id
LEFT JOIN transactions t
       ON t.user_id      = b.user_id
      AND (t.category_id = b.category_id OR b.category_id IS NULL)
      AND t.transaction_date BETWEEN b.period_start AND b.period_end
      AND t.transaction_type = 'EXPENSE'
      AND t.is_excluded = FALSE
WHERE b.is_active = TRUE
GROUP BY b.budget_id, b.user_id, b.name, c.name,
         b.budgeted_amount;

-- ── DAILY SPENDING TREND (last 90 days) ────────────────────
CREATE OR REPLACE VIEW vw_daily_spending_trend AS
SELECT
    user_id,
    summary_date,
    total_expenses,
    total_income,
    net_flow,
    AVG(total_expenses) OVER (
        PARTITION BY user_id
        ORDER BY summary_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )                                               AS rolling_7d_avg,
    AVG(total_expenses) OVER (
        PARTITION BY user_id
        ORDER BY summary_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    )                                               AS rolling_30d_avg
FROM daily_summaries
WHERE summary_date >= CURRENT_DATE - INTERVAL '90 days';

-- ── SAVINGS RATE ───────────────────────────────────────────
CREATE OR REPLACE VIEW vw_savings_rate AS
SELECT
    user_id,
    year,
    month,
    total_income,
    total_expenses,
    net_savings,
    savings_rate_pct,
    burn_rate,
    months_of_runway,
    predicted_next_month
FROM financial_snapshots;

-- ============================================================
-- SECTION 7: HELPER FUNCTIONS
-- ============================================================

-- Refresh daily summary for a user on a given date
CREATE OR REPLACE FUNCTION refresh_daily_summary(
    p_user_id INT,
    p_date    DATE
) RETURNS VOID AS $$
BEGIN
    INSERT INTO daily_summaries (user_id, summary_date, total_expenses,
                                  total_income, transaction_count)
    SELECT
        p_user_id,
        p_date,
        SUM(CASE WHEN transaction_type = 'EXPENSE' THEN amount ELSE 0 END),
        SUM(CASE WHEN transaction_type = 'INCOME'  THEN amount ELSE 0 END),
        COUNT(*)
    FROM transactions
    WHERE user_id = p_user_id
      AND transaction_date = p_date
      AND is_excluded = FALSE
    ON CONFLICT (user_id, summary_date)
    DO UPDATE SET
        total_expenses    = EXCLUDED.total_expenses,
        total_income      = EXCLUDED.total_income,
        transaction_count = EXCLUDED.transaction_count;
END;
$$ LANGUAGE plpgsql;

-- Auto-trigger: refresh daily summary whenever a transaction is inserted/updated
CREATE OR REPLACE FUNCTION trg_refresh_daily_summary()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM refresh_daily_summary(NEW.user_id, NEW.transaction_date);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_transaction_upsert
AFTER INSERT OR UPDATE ON transactions
FOR EACH ROW EXECUTE FUNCTION trg_refresh_daily_summary();

-- Compute spending consistency score (0-100)
-- Higher = more consistent day-to-day spending
CREATE OR REPLACE FUNCTION compute_consistency_score(
    p_user_id   INT,
    p_year      SMALLINT,
    p_month     SMALLINT
) RETURNS NUMERIC AS $$
DECLARE
    v_stddev    NUMERIC;
    v_mean      NUMERIC;
    v_cv        NUMERIC;
    v_score     NUMERIC;
BEGIN
    SELECT STDDEV(total_expenses), AVG(total_expenses)
      INTO v_stddev, v_mean
    FROM daily_summaries
    WHERE user_id = p_user_id
      AND EXTRACT(YEAR  FROM summary_date) = p_year
      AND EXTRACT(MONTH FROM summary_date) = p_month;

    IF v_mean IS NULL OR v_mean = 0 THEN
        RETURN NULL;
    END IF;

    -- Coefficient of variation → lower CV = more consistent
    v_cv    := v_stddev / v_mean;
    v_score := GREATEST(0, LEAST(100, ROUND(100 * (1 - LEAST(v_cv, 1)), 2)));
    RETURN v_score;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- SECTION 8: SAMPLE DATA
-- ============================================================

-- User
INSERT INTO users (username, email, currency, monthly_income)
VALUES ('alice', 'alice@example.com', 'USD', 5000.00);

-- Accounts
INSERT INTO accounts (user_id, name, account_type, balance, credit_limit, institution)
VALUES
(1, 'Chase Checking',   'CHECKING',    3200.00,    NULL,    'Chase'),
(1, 'Chase Savings',    'SAVINGS',     12500.00,   NULL,    'Chase'),
(1, 'Visa Credit Card', 'CREDIT_CARD', -450.00,    5000.00, 'Visa');

-- Tags
INSERT INTO tags (user_id, name) VALUES
(1, 'business'), (1, 'recurring'), (1, 'essential'), (1, 'luxury');

-- Sample transactions (current month)
INSERT INTO transactions
    (user_id, account_id, category_id, amount, transaction_type,
     merchant, transaction_date)
VALUES
(1, 1, 1, 1500.00, 'EXPENSE', 'Apartment Rent',    CURRENT_DATE - 15),
(1, 1, 7, 120.00,  'EXPENSE', 'Electric Bill',      CURRENT_DATE - 14),
(1, 1, 7,  60.00,  'EXPENSE', 'Internet',            CURRENT_DATE - 14),
(1, 1, 2,  85.50,  'EXPENSE', 'Whole Foods',         CURRENT_DATE - 10),
(1, 1, 2,  42.30,  'EXPENSE', 'Trader Joes',         CURRENT_DATE -  7),
(1, 3, 5,  15.99,  'EXPENSE', 'Netflix',             CURRENT_DATE -  5),
(1, 3, 5,  13.99,  'EXPENSE', 'Spotify',             CURRENT_DATE -  5),
(1, 1, 3,  45.00,  'EXPENSE', 'Uber',                CURRENT_DATE -  3),
(1, 1, 4,  90.00,  'EXPENSE', 'Gym Membership',      CURRENT_DATE -  2),
(1, 1,11,5000.00,  'INCOME',  'Monthly Salary',      CURRENT_DATE - 20);

-- Budget for Housing this month
INSERT INTO budgets (user_id, category_id, name, period_type, period_start, period_end, budgeted_amount)
VALUES
(1, 1, 'Housing Budget', 'MONTHLY',
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE,
    1600.00),
(1, 2, 'Food Budget', 'MONTHLY',
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE,
    400.00),
(1, 5, 'Entertainment Budget', 'MONTHLY',
    DATE_TRUNC('month', CURRENT_DATE)::DATE,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month - 1 day')::DATE,
    50.00);

-- ============================================================
-- SECTION 9: QUICK QUERY CHEATSHEET (as comments)
-- ============================================================

-- ## WHERE IS MONEY GOING (this month)?
-- SELECT * FROM vw_current_month_by_category WHERE user_id = 1 ORDER BY total_spent DESC;

-- ## WHICH CATEGORIES GROW FASTEST (last 6 months)?
-- SELECT * FROM vw_category_growth_mom WHERE user_id = 1
--   AND (year * 12 + month) >= (EXTRACT(YEAR FROM CURRENT_DATE)::INT * 12
--                                + EXTRACT(MONTH FROM CURRENT_DATE)::INT) - 6
--   ORDER BY growth_pct DESC NULLS LAST;

-- ## DAILY TREND (90 days)?
-- SELECT * FROM vw_daily_spending_trend WHERE user_id = 1 ORDER BY summary_date;

-- ## FIXED vs VARIABLE SPLIT?
-- SELECT * FROM vw_fixed_variable_split WHERE user_id = 1 ORDER BY month DESC;

-- ## BUDGET ADHERENCE (overspending)?
-- SELECT * FROM vw_budget_adherence WHERE user_id = 1 AND is_overspent = TRUE;

-- ## SAVINGS RATE & BURN RATE?
-- SELECT * FROM vw_savings_rate WHERE user_id = 1 ORDER BY year DESC, month DESC;

-- ## SPENDING CONSISTENCY SCORE (current month)?
-- SELECT compute_consistency_score(1,
--          EXTRACT(YEAR FROM CURRENT_DATE)::SMALLINT,
--          EXTRACT(MONTH FROM CURRENT_DATE)::SMALLINT);

-- ## ANOMALIES?
-- SELECT * FROM anomalies WHERE user_id = 1 AND is_false_positive = FALSE
--   ORDER BY detected_at DESC;

-- ## PREDICTED NEXT MONTH?
-- SELECT * FROM expense_predictions WHERE user_id = 1
--   AND target_year = EXTRACT(YEAR FROM CURRENT_DATE + INTERVAL '1 month')::SMALLINT
--   AND target_month = EXTRACT(MONTH FROM CURRENT_DATE + INTERVAL '1 month')::SMALLINT;