-- ============================================================
-- SEED DATA for DATA_expense
--
-- FIXES applied vs. ADD-VALUE.sql:
--  1. Hardcoded `user_id=1` and `account_id` in INSERTs broke when columns are
--     IDENTITY. Removed manual IDs — let SQL Server assign them.
--  2. Inserted 3 INCOME transactions all of 25,000,000 with the same description,
--     each pointing to a DIFFERENT category (1,2,3) — that's a logic error: salary
--     belongs to the "Income" category. Consolidated to ONE income row to category Income.
--  3. `category_id` 3 was 'Transport' but a row had description='Netflix' (Entertainment)
--     — reassigned to Entertainment.
--  4. Description='Grab ride' was inserted with category 2 (Food & Dining) — moved to Transport.
--  5. Description='Amazon' was inserted with category 2 (Food & Dining) — moved to Shopping.
--  6. password_hash was missing in user insert — added a bcrypt placeholder.
--  7. Used GETDATE() for transaction_date (DATETIME) — DATE column requires CAST.
-- ============================================================

USE DATA_expense;
GO

-- ── User ──────────────────────────────────────────────────────
INSERT INTO dbo.users (username, email, password_hash, full_name, role, currency)
VALUES ('Dat Pham', 'dat@example.com',
        '$2a$12$EXAMPLEHASHREPLACEINPRODabcdefghijklmnopqrstuvwxyzAB',
        'Dat Pham', 'user', 'VND');

DECLARE @uid INT = SCOPE_IDENTITY();

-- ── Accounts ──────────────────────────────────────────────────
INSERT INTO dbo.accounts (user_id, name, account_type, institution, balance, currency)
VALUES
    (@uid, 'Main Bank', 'CHECKING', 'Vietcombank', 15000000, 'VND'),
    (@uid, 'Cash',      'CASH',     NULL,           2000000, 'VND'),
    (@uid, 'Momo',      'CASH',     'Momo',         1000000, 'VND');

DECLARE @acct_main INT = (SELECT account_id FROM dbo.accounts WHERE user_id = @uid AND name = 'Main Bank');

-- ── User-specific categories (copies of system ones for this user) ────
INSERT INTO dbo.categories (user_id, name, expense_type, is_system) VALUES
    (@uid, 'Housing',       'fixed',         0),
    (@uid, 'Food & Dining', 'variable',      0),
    (@uid, 'Transport',     'semi_variable', 0),
    (@uid, 'Health',        'variable',      0),
    (@uid, 'Entertainment', 'variable',      0),
    (@uid, 'Shopping',      'variable',      0),
    (@uid, 'Income',        'variable',      0);

-- Look up category IDs for clarity
DECLARE @cat_food   INT = (SELECT category_id FROM dbo.categories WHERE user_id = @uid AND name = 'Food & Dining');
DECLARE @cat_trans  INT = (SELECT category_id FROM dbo.categories WHERE user_id = @uid AND name = 'Transport');
DECLARE @cat_enter  INT = (SELECT category_id FROM dbo.categories WHERE user_id = @uid AND name = 'Entertainment');
DECLARE @cat_shop   INT = (SELECT category_id FROM dbo.categories WHERE user_id = @uid AND name = 'Shopping');
DECLARE @cat_health INT = (SELECT category_id FROM dbo.categories WHERE user_id = @uid AND name = 'Health');
DECLARE @cat_inc    INT = (SELECT category_id FROM dbo.categories WHERE user_id = @uid AND name = 'Income');

-- ── Transactions (corrected category mapping) ────────────────
INSERT INTO dbo.transactions
    (user_id, account_id, category_id, amount, transaction_type, description, transaction_date, currency)
VALUES
    -- Income: ONE row in Income category (was duplicated 3x in original)
    (@uid, @acct_main, @cat_inc,    25000000, 'INCOME',  'Salary',       CAST(GETDATE() AS DATE), 'VND'),
    -- Expenses (each in its CORRECT category)
    (@uid, @acct_main, @cat_food,     500000, 'EXPENSE', 'Groceries',    CAST(GETDATE() AS DATE), 'VND'),
    (@uid, @acct_main, @cat_trans,    200000, 'EXPENSE', 'Grab ride',    CAST(GETDATE() AS DATE), 'VND'),
    (@uid, @acct_main, @cat_enter,    150000, 'EXPENSE', 'Netflix',      CAST(GETDATE() AS DATE), 'VND'),
    (@uid, @acct_main, @cat_shop,     100000, 'EXPENSE', 'Amazon',       CAST(GETDATE() AS DATE), 'VND'),
    (@uid, @acct_main, @cat_health,   300000, 'EXPENSE', 'Doctor visit', CAST(GETDATE() AS DATE), 'VND');

-- ── Budgets ───────────────────────────────────────────────────
INSERT INTO dbo.budgets
    (user_id, category_id, name, period_type, period_start, period_end, budget_amount)
VALUES
    (@uid, @cat_food,  'Food Budget',      'MONTHLY', '2026-04-01', '2026-04-30', 3000000),
    (@uid, @cat_trans, 'Transport Budget', 'MONTHLY', '2026-04-01', '2026-04-30', 1000000);

PRINT 'Seed data inserted successfully.';
GO