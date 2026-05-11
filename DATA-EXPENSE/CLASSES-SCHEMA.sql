
USE DATA_expense;


IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'DATA_expense')
BEGIN
    CREATE DATABASE DATA_expense;
    USE DATA_expense;

END
GO

GO
-- ============================================================
--  PERSONAL FINANCE DATABASE
--  Supports: Expense Analysis, Behavior & Insights,
--            Financial Health & Predictive Analytics
-- ============================================================


-- ============================================================
-- SECTION 1: CORE REFERENCE TABLES
-- ============================================================


CREATE TABLE dbo.users (
    user_id     INT IDENTITY(1,1) PRIMARY KEY,
    username    NVARCHAR(100) NOT NULL UNIQUE,
    email       NVARCHAR(255) NOT NULL UNIQUE,
    password_hash NVARCHAR(255) NOT NULL,
    full_name   NVARCHAR(150),
    role        NVARCHAR(20) NOT NULL DEFAULT 'user'
                    CHECK (role IN ('user','manager','admin')),
    is_active   BIT NOT NULL DEFAULT 1,
    last_login  DATETIME2,
    currency    CHAR(5) NOT NULL DEFAULT 'USD',
    created_at  DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at  DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    row_version ROWVERSION
);

-- ──────────────────────────────────────────────────────────
-- Categories: hierarchical (parent → child)
-- expense_type: FIXED | VARIABLE | SEMI_VARIABLE
-- ──────────────────────────────────────────────────────────

CREATE TABLE dbo.categories (
    category_id  INT IDENTITY(1,1) PRIMARY KEY,
    user_id      INT NULL REFERENCES dbo.users(user_id) ON DELETE CASCADE,
    parent_id    INT NULL REFERENCES dbo.categories(category_id),
    name         NVARCHAR(100) NOT NULL,
    icon         NVARCHAR(255) NULL,
    color        NVARCHAR(7) NULL,
    expense_type NVARCHAR(20) NOT NULL DEFAULT 'variable'
                    CHECK (expense_type IN ('fixed','variable','semi_variable')),
    is_system    BIT NOT NULL DEFAULT 0,
    created_at   DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at   DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

-- Seed: system-level categories
INSERT INTO dbo.categories (user_id, parent_id, name, expense_type, is_system) VALUES
(NULL, NULL, 'Housing',           'fixed',        1),
(NULL, NULL, 'Food & Dining',     'variable',     1),
(NULL, NULL, 'Transport',         'semi_variable', 1),
(NULL, NULL, 'Health',            'variable',     1),
(NULL, NULL, 'Entertainment',     'variable',     1),
(NULL, NULL, 'Shopping',          'variable',     1),
(NULL, NULL, 'Utilities',         'semi_variable', 1),
(NULL, NULL, 'Education',         'fixed',        1),
(NULL, NULL, 'Personal Care',     'variable',     1),
(NULL, NULL, 'Savings',           'fixed',        1),
(NULL, NULL, 'Income',            'variable',     1);


CREATE TABLE dbo.accounts (
    account_id   INT IDENTITY(1,1) PRIMARY KEY,
    user_id      INT NOT NULL REFERENCES dbo.users(user_id),
    name         NVARCHAR(100) NOT NULL,
    account_type NVARCHAR(30) NOT NULL
                    CHECK (account_type IN ('CHECKING','SAVING','CREDIT_CARD','CASH','INVESTMENT','LOAN')),
    balance      DECIMAL(14,2) NOT NULL DEFAULT 0,
    credit_limit DECIMAL(14,2),
    currency     CHAR(5) NOT NULL DEFAULT 'VND',
    institution  NVARCHAR(100),
    is_active    BIT NOT NULL DEFAULT 1,
    created_at   DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

-- ──────────────────────────────────────────────────────────
-- Tags: flexible labeling (e.g. "business", "recurring")
-- ──────────────────────────────────────────────────────────


CREATE TABLE dbo.tags (
    tags_id  INT IDENTITY(1,1) PRIMARY KEY,
    user_id  INT NOT NULL REFERENCES dbo.users(user_id),
    name     NVARCHAR(50) NOT NULL,
    CONSTRAINT uq_tags_user_name UNIQUE (user_id, name)
);

-- ============================================================
-- SECTION 2: TRANSACTIONS
-- ============================================================


CREATE TABLE dbo.transactions (
    transaction_id       INT IDENTITY(1,1) PRIMARY KEY,
    user_id              INT NOT NULL REFERENCES dbo.users(user_id),
    account_id           INT NOT NULL REFERENCES dbo.accounts(account_id),
    category_id          INT REFERENCES dbo.categories(category_id),

	-- Core amounts

    amount               NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    currency             CHAR(5) NOT NULL DEFAULT 'VND',
    amount_base_currency NUMERIC(14,2),
    exchange_rate        NUMERIC(12,6) DEFAULT 1.0,

	-- Direction & type
    transaction_type     NVARCHAR(20) NOT NULL
                            CHECK (transaction_type IN ('EXPENSE','INCOME','TRANSFER','REFUND','INVESTMENT')),
    is_recurring         BIT NOT NULL DEFAULT 0,
    recurrence_id        INT,

	-- Metadata
	merchant		    NVARCHAR(255),
	description		    NVARCHAR(MAX),
	notes			    NVARCHAR(MAX),
	transaction_date    DATE NOT NULL,
	posted_date		    DATE,

	-- Location (optional, for geo-analytics)
	latitude            NUMERIC(9,6),
    longitude           NUMERIC(9,6),
    city                NVARCHAR(100),
    country             CHAR(2),

	-- Flags 
    is_verified          BIT NOT NULL DEFAULT 0,
    is_excluded          BIT NOT NULL DEFAULT 0,
    created_at           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at           DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    row_version          ROWVERSION
);

-- Many-to-many: transactions ↔ tags
CREATE TABLE dbo.transaction_tags (
    transaction_id INT NOT NULL REFERENCES dbo.transactions(transaction_id) ON DELETE CASCADE,
    tags_id        INT NOT NULL REFERENCES dbo.tags(tags_id) ON DELETE CASCADE,
    PRIMARY KEY (transaction_id, tags_id)
);

-- ──────────────────────────────────────────────────────────
-- Recurring rules (subscriptions, rent, salary, etc.)
-- ──────────────────────────────────────────────────────────

CREATE TABLE dbo.recurring_rules (
    recurrence_id        INT IDENTITY(1,1) PRIMARY KEY,
    user_id              INT NOT NULL REFERENCES dbo.users(user_id),
    account_id           INT NOT NULL REFERENCES dbo.accounts(account_id),
    category_id          INT REFERENCES dbo.categories(category_id),
    amount               DECIMAL(14,2) NOT NULL CHECK (amount > 0),
    description          NVARCHAR(255),
    frequency            NVARCHAR(20) NOT NULL
                            CHECK (frequency IN ('DAILY','WEEKLY','BIWEEKLY','MONTHLY','QUARTERLY','ANNUALLY')),
    start_date           DATE NOT NULL,
    end_date             DATE,
    last_generated_date  DATE,
    is_active            BIT NOT NULL DEFAULT 1,
    created_at           DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

-- Back-fill FK
ALTER TABLE dbo.transactions
    ADD CONSTRAINT fk_recurrence
    FOREIGN KEY (recurrence_id)
    REFERENCES dbo.recurring_rules(recurrence_id);

-- ============================================================
-- SECTION 3: BUDGETS
-- ============================================================

CREATE TABLE dbo.budgets (
    budget_id        INT IDENTITY(1,1) PRIMARY KEY,
    user_id          INT NOT NULL REFERENCES dbo.users(user_id),
    category_id      INT NULL REFERENCES dbo.categories(category_id),
    name             NVARCHAR(100) NOT NULL,
    period_type      NVARCHAR(10) NOT NULL DEFAULT 'MONTHLY'
                        CHECK (period_type IN ('WEEKLY','MONTHLY','QUARTERLY','YEARLY','CUSTOM')),
    period_start     DATE NOT NULL,
    period_end       DATE NOT NULL,
    budget_amount    DECIMAL(14,2) NOT NULL CHECK (budget_amount > 0),
    rollover         BIT NOT NULL DEFAULT 0,
    alert_threshold  DECIMAL(5,2) NOT NULL DEFAULT 80.00
                        CHECK (alert_threshold > 0 AND alert_threshold <= 100),
    is_active        BIT NOT NULL DEFAULT 1,
    created_at       DATETIME2 NOT NULL DEFAULT SYSDATETIME());

-- ============================================================
-- SECTION 4: ANALYTICS SUPPORT TABLES
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- Daily aggregates — pre-computed for speed
-- (populated by trigger or scheduled job)
-- ──────────────────────────────────────────────────────────

CREATE TABLE dbo.daily_summaries (
    daily_summary_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id          INT NOT NULL REFERENCES dbo.users(user_id),
    summary_date     DATE NOT NULL,
    total_expense    DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_income     DECIMAL(14,2) NOT NULL DEFAULT 0,
    net_amount       DECIMAL(14,2) NOT NULL DEFAULT 0,
    CONSTRAINT uq_daily_summary UNIQUE (user_id, summary_date)
);

CREATE TABLE dbo.monthly_category_totals (
    mc_total_id       INT IDENTITY(1,1) PRIMARY KEY,
    user_id           INT NOT NULL REFERENCES dbo.users(user_id),
    category_id       INT NOT NULL REFERENCES dbo.categories(category_id),
    year              SMALLINT NOT NULL,
    month             SMALLINT NOT NULL CHECK (month BETWEEN 1 AND 12),
    total_amount      DECIMAL(14,2) NOT NULL DEFAULT 0,
    transaction_count INT NOT NULL DEFAULT 0,
    avg_transaction   DECIMAL(14,2),
    CONSTRAINT uq_mct UNIQUE (user_id, category_id, year, month)
);

-- ──────────────────────────────────────────────────────────
-- Spending scores & health snapshots
-- (one row per user per month)
-- ──────────────────────────────────────────────────────────

CREATE TABLE dbo.financial_snapshots (
    snapshot_id                 INT IDENTITY(1,1) PRIMARY KEY,
    user_id                     INT NOT NULL REFERENCES dbo.users(user_id) ON DELETE CASCADE,
    year                        SMALLINT NOT NULL,
    month                       SMALLINT NOT NULL CHECK (month BETWEEN 1 AND 12),
    total_expenses              DECIMAL(14,2),
    total_income                DECIMAL(14,2),
    net_savings                 DECIMAL(14,2),
    savings_rate_pct            DECIMAL(6,3),
    fixed_expense_total         DECIMAL(14,2),
    variable_expense_total      DECIMAL(14,2),
    budget_adherence_pct        DECIMAL(6,3),
    overspent_categories        NVARCHAR(MAX),
    anomaly_flags               NVARCHAR(MAX),
    spending_consistency_score  DECIMAL(5,2),
    burn_rate                   DECIMAL(14,2),
    predicted_next_month        DECIMAL(14,2),
    months_of_runway            DECIMAL(6,2),
    computed_at                 DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT uq_snapshot UNIQUE (user_id, year, month)
);
-- ──────────────────────────────────────────────────────────-- Monthly category totals — for trend & anomaly queries-- ──────────────────────────────────────────────────────────
-- ──────────────────────────────────────────────────────────
-- Anomaly log — detected individually
-- ──────────────────────────────────────────────────────────
CREATE TABLE dbo.anomalies (
    anomaly_id        INT IDENTITY(1,1) PRIMARY KEY,
    user_id           INT NOT NULL REFERENCES dbo.users(user_id) ON DELETE CASCADE,
    transaction_id    INT REFERENCES dbo.transactions(transaction_id),
    category_id       INT REFERENCES dbo.categories(category_id),
    anomaly_type      NVARCHAR(50) NOT NULL
                        CHECK (anomaly_type IN (
                            'OVERSPEND','UNUSUAL_MERCHANT','LARGE_TRANSACTION',
                            'FREQUENCY_SPIKE','CATEGORY_GROWTH','BUDGET_BREACH'
                        )),
    severity          NVARCHAR(10) NOT NULL DEFAULT 'MEDIUM'
                        CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    description       NVARCHAR(MAX),
    detected_at       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    acknowledged_at   DATETIME2,
    is_false_positive BIT NOT NULL DEFAULT 0
);


-- ============================================================
-- SECTION 4b: AUDIT LOG (added — required by Business Logic service)
-- ============================================================
CREATE TABLE dbo.audit_logs (
    audit_id    BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id     INT NULL REFERENCES dbo.users(user_id),
    action      NVARCHAR(20) NOT NULL,           -- CREATE | UPDATE | DELETE | LOGIN | LOGOUT
    table_name  NVARCHAR(50) NOT NULL,
    record_id   INT NULL,
    old_values  NVARCHAR(MAX),                   -- JSON
    new_values  NVARCHAR(MAX),                   -- JSON
    ip_address  NVARCHAR(45),
    user_agent  NVARCHAR(500),
    created_at  DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO
 
CREATE INDEX idx_audit_user_date ON dbo.audit_logs (user_id, created_at DESC);
CREATE INDEX idx_audit_table_action ON dbo.audit_logs (table_name, action);
GO

-- ============================================================
-- SECTION 5: INDEXES
-- ============================================================
CREATE INDEX idx_txn_user_date     ON dbo.transactions (user_id, transaction_date DESC);
CREATE INDEX idx_txn_user_category ON dbo.transactions (user_id, category_id, transaction_date DESC);
CREATE INDEX idx_mct_user_period   ON dbo.monthly_category_totals (user_id, year DESC, month DESC);
CREATE INDEX idx_anomaly_user      ON dbo.anomalies (user_id, detected_at DESC);
CREATE INDEX idx_txn_recurrence    ON dbo.transactions (recurrence_id) WHERE recurrence_id IS NOT NULL;
CREATE INDEX idx_budget_user_period ON dbo.budgets (user_id, period_start, period_end);
GO
 
-- ============================================================
-- TRIGGERS
-- ============================================================
CREATE TRIGGER trg_users_updated_at
ON dbo.users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.users
    SET updated_at = SYSUTCDATETIME()
    FROM dbo.users u
    INNER JOIN inserted i ON u.user_id = i.user_id;
END;
GO
 
-- ============================================================
-- SECTION 6: VIEWS
-- ============================================================
CREATE OR ALTER VIEW vw_current_month_by_category AS
SELECT
    t.user_id,
    c.name           AS category,
    c.expense_type,
    SUM(t.amount)    AS total_spent,
    COUNT(*)         AS txn_count,
    ROUND(AVG(t.amount), 2) AS avg_per_txn
FROM dbo.transactions t
JOIN dbo.categories c ON c.category_id = t.category_id
WHERE t.transaction_type = 'EXPENSE'
  AND t.is_excluded = 0
  AND DATEPART(YEAR, t.transaction_date)  = DATEPART(YEAR, GETDATE())
  AND DATEPART(MONTH, t.transaction_date) = DATEPART(MONTH, GETDATE())
GROUP BY t.user_id, c.name, c.expense_type;
GO
 
CREATE OR ALTER VIEW vw_fixed_variable_split AS
SELECT
    t.user_id,
    DATEFROMPARTS(YEAR(t.transaction_date), MONTH(t.transaction_date), 1) AS month,
    SUM(CASE WHEN c.expense_type = 'fixed'         THEN t.amount ELSE 0 END) AS fixed_total,
    SUM(CASE WHEN c.expense_type = 'variable'      THEN t.amount ELSE 0 END) AS variable_total,
    SUM(CASE WHEN c.expense_type = 'semi_variable' THEN t.amount ELSE 0 END) AS semi_variable_total,
    SUM(t.amount) AS grand_total
FROM dbo.transactions t
JOIN dbo.categories c ON c.category_id = t.category_id
WHERE t.transaction_type = 'EXPENSE'
  AND t.is_excluded = 0
GROUP BY t.user_id, DATEFROMPARTS(YEAR(t.transaction_date), MONTH(t.transaction_date), 1);
GO
 
CREATE OR ALTER VIEW vw_budget_adherence AS
SELECT
    b.user_id,
    b.budget_id,
    b.name AS budget_name,
    b.budget_amount,
    COALESCE(SUM(t.amount), 0) AS spent_amount,
    b.budget_amount - COALESCE(SUM(t.amount), 0) AS remaining,
    ROUND(COALESCE(SUM(t.amount), 0) / NULLIF(b.budget_amount, 0) * 100, 2) AS pct_used,
    CASE WHEN COALESCE(SUM(t.amount), 0) > b.budget_amount THEN 1 ELSE 0 END AS is_overspent
FROM dbo.budgets b
LEFT JOIN dbo.transactions t
    ON t.user_id          = b.user_id
   AND t.transaction_date BETWEEN b.period_start AND b.period_end
   AND t.transaction_type = 'EXPENSE'
   AND t.is_excluded      = 0
   AND (b.category_id IS NULL OR t.category_id = b.category_id)
WHERE b.is_active = 1
GROUP BY b.user_id, b.budget_id, b.name, b.budget_amount;
GO
 
CREATE OR ALTER VIEW vw_daily_spending_trend AS
SELECT
    user_id,
    summary_date,
    total_expense,
    total_income,
    net_amount,
    
    AVG(total_expense) OVER (
        PARTITION BY user_id
        ORDER BY summary_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7d_avg,

    AVG(total_expense) OVER (
        PARTITION BY user_id
        ORDER BY summary_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS rolling_30d_avg
FROM dbo.daily_summaries
WHERE summary_date >= DATEADD(DAY, -90, GETDATE());
GO
 
-- ============================================================
-- SECTION 7: HELPER PROCEDURES
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.refresh_daily_summary
    @p_user_id INT,
    @p_date    DATE
AS
BEGIN
    SET NOCOUNT ON;
    MERGE dbo.daily_summaries AS target
    USING (
        SELECT
            @p_user_id AS user_id,
            @p_date    AS summary_date,
            COALESCE(SUM(CASE WHEN transaction_type = 'EXPENSE' THEN amount ELSE 0 END), 0) AS total_expense,
            COALESCE(SUM(CASE WHEN transaction_type = 'INCOME'  THEN amount ELSE 0 END), 0) AS total_income
        FROM dbo.transactions
        WHERE user_id          = @p_user_id
          AND transaction_date = @p_date
          AND is_excluded      = 0
    ) AS src
    ON target.user_id = src.user_id
    AND target.summary_date = src.summary_date
    WHEN MATCHED THEN UPDATE SET
        total_expense = src.total_expense,
        total_income  = src.total_income,
        net_amount    = src.total_income - src.total_expense
    WHEN NOT MATCHED THEN
        INSERT (user_id, summary_date, total_expense, total_income, net_amount)
        VALUES (src.user_id, src.summary_date, src.total_expense, src.total_income,
                src.total_income - src.total_expense);
END;
GO
 
-- Seed: system-level categories (NULL user_id = available to everyone)
INSERT INTO dbo.categories (user_id, parent_id, name, expense_type, is_system) VALUES
(NULL, NULL, 'Housing',        'fixed',         1),
(NULL, NULL, 'Food & Dining',  'variable',      1),
(NULL, NULL, 'Transport',      'semi_variable', 1),
(NULL, NULL, 'Health',         'variable',      1),
(NULL, NULL, 'Entertainment',  'variable',      1),
(NULL, NULL, 'Shopping',       'variable',      1),
(NULL, NULL, 'Utilities',      'semi_variable', 1),
(NULL, NULL, 'Education',      'fixed',         1),
(NULL, NULL, 'Personal Care',  'variable',      1),
(NULL, NULL, 'Savings',        'fixed',         1),
(NULL, NULL, 'Income',         'variable',      1);
GO
 
PRINT 'DATA_expense schema created successfully.';
GO