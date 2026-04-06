-- ============================================================
--  SEED DATA — DATA_expense (Personal Finance Database)
--  Compatible: SQL Server 2016+  (MSSQL)
--  Currency: VND (Vietnamese Dong) — primary currency
--  Users: 3 sample users with realistic Vietnamese finance data
--  Coverage: ALL tables except row_version / computed columns
-- ============================================================

USE DATA_expense;
GO

-- Disable triggers during bulk insert to avoid premature summary refresh
DISABLE TRIGGER after_transaction_upsert ON transactions;
GO

-- ============================================================
-- SECTION 1: USERS
-- ============================================================

SET IDENTITY_INSERT dbo.users OFF;   -- user_id is plain INT (no IDENTITY)

INSERT INTO dbo.users (user_id, username, email, currency)
VALUES
    (1, N'nguyen_van_an',   N'an.nguyen@email.vn',    'VND'),
    (2, N'tran_thi_bich',   N'bich.tran@email.vn',    'VND'),
    (3, N'le_minh_khoa',    N'khoa.le@email.vn',      'VND');

-- ============================================================
-- SECTION 2: CATEGORIES
-- ============================================================
-- System categories (is_system = 1) already seeded by schema.
-- category_id 1-11 reserved. User-defined sub-categories start at 12.

-- Sub-categories for User 1 (nguyen_van_an)
INSERT INTO dbo.categories (user_id, parent_id, name, expense_type, is_system) VALUES
-- Housing children
(1, 1, N'Rent',                'fixed',        0),
(1, 1, N'Home Maintenance',    'variable',     0),
-- Food & Dining children
(1, 2, N'Groceries',           'variable',     0),
(1, 2, N'Restaurants',         'variable',     0),
(1, 2, N'Coffee & Drinks',     'variable',     0),
-- Transport children
(1, 3, N'Fuel',                'semi_variable',0),
(1, 3, N'Grab / Taxi',         'variable',     0),
-- Health children
(1, 4, N'Pharmacy',            'variable',     0),
(1, 4, N'Gym Membership',      'fixed',        0),
-- Entertainment children
(1, 5, N'Streaming Services',  'fixed',        0),
(1, 5, N'Games',               'variable',     0),
-- Utilities children
(1, 7, N'Electricity',         'semi_variable',0),
(1, 7, N'Internet',            'fixed',        0),
(1, 7, N'Water',               'semi_variable',0);

-- Sub-categories for User 2 (tran_thi_bich)
INSERT INTO dbo.categories (user_id, parent_id, name, expense_type, is_system) VALUES
(2, 2, N'Groceries',           'variable',     0),
(2, 2, N'Coffee & Drinks',     'variable',     0),
(2, 3, N'Motorbike Fuel',      'semi_variable',0),
(2, 6, N'Clothing',            'variable',     0),
(2, 6, N'Cosmetics',           'variable',     0),
(2, 7, N'Electricity',         'semi_variable',0),
(2, 7, N'Internet',            'fixed',        0),
(2, 8, N'Online Course',       'fixed',        0);

-- Sub-categories for User 3 (le_minh_khoa)
INSERT INTO dbo.categories (user_id, parent_id, name, expense_type, is_system) VALUES
(3, 1, N'Rent',                'fixed',        0),
(3, 2, N'Groceries',           'variable',     0),
(3, 2, N'Restaurants',         'variable',     0),
(3, 3, N'Grab / Taxi',         'variable',     0),
(3, 5, N'Streaming Services',  'fixed',        0),
(3, 7, N'Electricity',         'semi_variable',0),
(3, 7, N'Internet',            'fixed',        0),
(3, 10,N'Emergency Fund',      'fixed',        0);

-- ============================================================
-- SECTION 3: ACCOUNTS
-- ============================================================

INSERT INTO dbo.accounts (account_id, user_id, name, account_type, balance, credit_limit, currency, institution, is_active)
VALUES
-- User 1: nguyen_van_an
(101, 1, N'Vietcombank Checking',    'CHECKING',     15500000,   NULL,        'VND', N'Vietcombank',     1),
(102, 1, N'Techcombank Savings',     'SAVING',       42000000,   NULL,        'VND', N'Techcombank',     1),
(103, 1, N'VPBank Credit Card',      'CREDIT_CARD',  -3200000,   50000000,    'VND', N'VPBank',          1),
(104, 1, N'Cash Wallet',             'CASH',         1200000,    NULL,        'VND', NULL,               1),

-- User 2: tran_thi_bich
(201, 2, N'BIDV Checking',           'CHECKING',     8700000,    NULL,        'VND', N'BIDV',            1),
(202, 2, N'MB Bank Savings',         'SAVING',       25000000,   NULL,        'VND', N'MB Bank',         1),
(203, 2, N'Sacombank Credit Card',   'CREDIT_CARD',  -1500000,   30000000,    'VND', N'Sacombank',       1),

-- User 3: le_minh_khoa
(301, 3, N'ACB Checking',            'CHECKING',     22000000,   NULL,        'VND', N'ACB',             1),
(302, 3, N'Shinhan Bank Savings',    'SAVING',       60000000,   NULL,        'VND', N'Shinhan Bank',    1),
(303, 3, N'MOMO Wallet',             'CASH',         800000,     NULL,        'VND', N'MoMo',            1);

-- ============================================================
-- SECTION 4: TAGS
-- ============================================================

INSERT INTO tags (tags_id, user_id, name)
VALUES
-- User 1 tags
(1,  1, N'business'),
(2,  1, N'recurring'),
(3,  1, N'essential'),
(4,  1, N'impulse'),
(5,  1, N'online'),
-- User 2 tags
(6,  2, N'recurring'),
(7,  2, N'essential'),
(8,  2, N'weekend'),
(9,  2, N'online'),
-- User 3 tags
(10, 3, N'recurring'),
(11, 3, N'essential'),
(12, 3, N'work'),
(13, 3, N'online');

-- ============================================================
-- SECTION 5: RECURRING RULES
-- ============================================================

INSERT INTO recurring_rules
    (recurrence_id, user_id, account_id, category_id, amount, description, frequency, start_date, end_date, last_generated_date, is_active)
VALUES
-- User 1
(1, 1, 101,  12, 6000000,  N'Monthly Apartment Rent',      'MONTHLY',   '2024-01-01', NULL,         '2026-03-01', 1),
(2, 1, 101,  21, 220000,   N'Netflix Subscription',        'MONTHLY',   '2023-06-01', NULL,         '2026-03-01', 1),
(3, 1, 101,  23, 265000,   N'FPT Internet Monthly',        'MONTHLY',   '2023-01-01', NULL,         '2026-03-01', 1),
(4, 1, 101,  20, 200000,   N'Gym California Monthly',      'MONTHLY',   '2024-03-01', NULL,         '2026-03-01', 1),

-- User 2
(5, 2, 201,  34, 180000,   N'FPT Internet Monthly',        'MONTHLY',   '2023-09-01', NULL,         '2026-03-01', 1),
(6, 2, 201,  35, 450000,   N'Coursera Subscription',       'MONTHLY',   '2025-01-01', NULL,         '2026-03-01', 1),

-- User 3
(7, 3, 301,  37, 7500000,  N'Monthly Apartment Rent',      'MONTHLY',   '2024-06-01', NULL,         '2026-03-01', 1),
(8, 3, 301,  43, 265000,   N'Internet Viettel Monthly',    'MONTHLY',   '2024-06-01', NULL,         '2026-03-01', 1),
(9, 3, 301,  42, 199000,   N'Spotify Premium',             'MONTHLY',   '2024-09-01', NULL,         '2026-03-01', 1);

-- ============================================================
-- SECTION 6: BUDGETS
-- ============================================================

INSERT INTO budgets
    (budget_id, user_id, name, period_type, period_start, period_end, budget_amount, rollover, alert_threshold, is_active)
VALUES
-- User 1 — Q1 2026
(1,  1, N'Monthly Total Q1-2026',    'MONTHLY',   '2026-01-01', '2026-01-31', 15000000, 0, 80.00, 1),
(2,  1, N'Food & Dining Jan 2026',   'MONTHLY',   '2026-01-01', '2026-01-31',  3000000, 0, 80.00, 1),
(3,  1, N'Monthly Total Feb-2026',   'MONTHLY',   '2026-02-01', '2026-02-28', 15000000, 0, 80.00, 1),
(4,  1, N'Monthly Total Mar-2026',   'MONTHLY',   '2026-03-01', '2026-03-31', 15000000, 0, 80.00, 1),
(5,  1, N'Q1 2026 Overall',          'QUARTERLY', '2026-01-01', '2026-03-31', 45000000, 0, 85.00, 1),

-- User 2 — Q1 2026
(6,  2, N'Monthly Total Jan-2026',   'MONTHLY',   '2026-01-01', '2026-01-31',  9000000, 0, 80.00, 1),
(7,  2, N'Shopping Budget Q1',       'QUARTERLY', '2026-01-01', '2026-03-31',  6000000, 0, 75.00, 1),

-- User 3 — Q1 2026
(8,  3, N'Monthly Total Jan-2026',   'MONTHLY',   '2026-01-01', '2026-01-31', 18000000, 0, 80.00, 1),
(9,  3, N'Monthly Total Feb-2026',   'MONTHLY',   '2026-02-01', '2026-02-28', 18000000, 0, 80.00, 1),
(10, 3, N'Monthly Total Mar-2026',   'MONTHLY',   '2026-03-01', '2026-03-31', 18000000, 0, 80.00, 1);

-- ============================================================
-- SECTION 7: TRANSACTIONS
-- Realistic VND amounts for Ho Chi Minh City lifestyle
-- Covers: Jan 2026, Feb 2026, Mar 2026 (3 full months)
-- ============================================================

INSERT INTO transactions
    (transaction_id, user_id, account_id, category_id,
     amount, currency, amount_base_currency, exchange_rate,
     transaction_type, is_recurring, recurrence_id,
     merchant, description, notes,
     transaction_date, posted_date,
     latitude, longitude, city, country,
     is_verified, is_excluded)
VALUES

-- ===========================================================
-- USER 1 — nguyen_van_an  (Jan 2026)
-- ===========================================================

-- INCOME
(10001, 1, 101, 11, 22000000, 'VND', 22000000, 1.0, 'INCOME',   0, NULL,
 N'Công ty ABC',    N'Lương tháng 1/2026',     NULL,  '2026-01-05', '2026-01-05',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

-- FIXED: Rent
(10002, 1, 101, 12, 6000000, 'VND', 6000000, 1.0, 'EXPENSE', 1, 1,
 N'Chủ nhà Quận 7',  N'Tiền thuê nhà tháng 1', NULL, '2026-01-01', '2026-01-01',
 10.7320, 106.7220, N'Ho Chi Minh City', 'VN', 1, 0),

-- Internet
(10003, 1, 101, 23, 265000, 'VND', 265000, 1.0, 'EXPENSE', 1, 3,
 N'FPT Telecom',  N'Internet tháng 1', NULL, '2026-01-03', '2026-01-03',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Electricity
(10004, 1, 101, 22, 410000, 'VND', 410000, 1.0, 'EXPENSE', 0, NULL,
 N'EVN',  N'Tiền điện tháng 1', NULL, '2026-01-04', '2026-01-04',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Groceries
(10005, 1, 101, 14, 850000, 'VND', 850000, 1.0, 'EXPENSE', 0, NULL,
 N'VinMart Quận 7', N'Mua sắm tạp hóa tuần 1', NULL, '2026-01-06', '2026-01-06',
 10.7320, 106.7220, N'Ho Chi Minh City', 'VN', 1, 0),

(10006, 1, 101, 14, 720000, 'VND', 720000, 1.0, 'EXPENSE', 0, NULL,
 N'Co.opmart',      N'Mua sắm tạp hóa tuần 2', NULL, '2026-01-13', '2026-01-13',
 10.7769, 106.6990, N'Ho Chi Minh City', 'VN', 1, 0),

(10007, 1, 101, 14, 900000, 'VND', 900000, 1.0, 'EXPENSE', 0, NULL,
 N'BigC An Lạc',    N'Mua sắm tạp hóa tuần 3', NULL, '2026-01-20', '2026-01-20',
 10.7425, 106.6279, N'Ho Chi Minh City', 'VN', 1, 0),

(10008, 1, 101, 14, 650000, 'VND', 650000, 1.0, 'EXPENSE', 0, NULL,
 N'VinMart Quận 7', N'Mua sắm tạp hóa tuần 4', NULL, '2026-01-27', '2026-01-27',
 10.7320, 106.7220, N'Ho Chi Minh City', 'VN', 1, 0),

-- Restaurants
(10009, 1, 101, 15, 180000, 'VND', 180000, 1.0, 'EXPENSE', 0, NULL,
 N'Phở Hùng',       N'Ăn trưa với đồng nghiệp', NULL, '2026-01-07', '2026-01-07',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

(10010, 1, 103, 15, 450000, 'VND', 450000, 1.0, 'EXPENSE', 0, NULL,
 N'Lẩu Thái E-Town', N'Ăn tối cùng bạn bè', NULL, '2026-01-10', '2026-01-10',
 10.7994, 106.6660, N'Ho Chi Minh City', 'VN', 1, 0),

(10011, 1, 103, 15, 220000, 'VND', 220000, 1.0, 'EXPENSE', 0, NULL,
 N'Cơm Tấm Cali',   N'Ăn cơm trưa', NULL, '2026-01-14', '2026-01-14',
 10.7890, 106.6890, N'Ho Chi Minh City', 'VN', 1, 0),

(10012, 1, 103, 15, 380000, 'VND', 380000, 1.0, 'EXPENSE', 0, NULL,
 N'Pizza 4P\'s',     N'Sinh nhật bạn', NULL, '2026-01-17', '2026-01-17',
 10.7820, 106.7010, N'Ho Chi Minh City', 'VN', 1, 0),

(10013, 1, 101, 15, 150000, 'VND', 150000, 1.0, 'EXPENSE', 0, NULL,
 N'Bánh Mì Huỳnh Hoa', N'Ăn sáng', NULL, '2026-01-22', '2026-01-22',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

-- Coffee
(10014, 1, 104, 16, 65000, 'VND', 65000, 1.0, 'EXPENSE', 0, NULL,
 N'Highlands Coffee', N'Cà phê sáng', NULL, '2026-01-08', '2026-01-08',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

(10015, 1, 104, 16, 75000, 'VND', 75000, 1.0, 'EXPENSE', 0, NULL,
 N'The Coffee House',  N'Làm việc buổi chiều', NULL, '2026-01-12', '2026-01-12',
 10.7780, 106.7020, N'Ho Chi Minh City', 'VN', 1, 0),

(10016, 1, 104, 16, 55000, 'VND', 55000, 1.0, 'EXPENSE', 0, NULL,
 N'Phúc Long',         N'Cà phê sáng', NULL, '2026-01-19', '2026-01-19',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

(10017, 1, 104, 16, 80000, 'VND', 80000, 1.0, 'EXPENSE', 0, NULL,
 N'Starbucks Landmark', N'Họp với khách hàng', NULL, '2026-01-23', '2026-01-23',
 10.7816, 106.6981, N'Ho Chi Minh City', 'VN', 1, 0),

-- Grab
(10018, 1, 103, 18, 45000, 'VND', 45000, 1.0, 'EXPENSE', 0, NULL,
 N'Grab',  N'Đi làm buổi sáng', NULL, '2026-01-09', '2026-01-09',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10019, 1, 103, 18, 62000, 'VND', 62000, 1.0, 'EXPENSE', 0, NULL,
 N'Grab',  N'Về nhà buổi tối', NULL, '2026-01-16', '2026-01-16',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Gym
(10020, 1, 101, 20, 200000, 'VND', 200000, 1.0, 'EXPENSE', 1, 4,
 N'California Fitness', N'Phí tháng gym', NULL, '2026-01-02', '2026-01-02',
 10.7816, 106.6981, N'Ho Chi Minh City', 'VN', 1, 0),

-- Netflix
(10021, 1, 101, 21, 220000, 'VND', 220000, 1.0, 'EXPENSE', 1, 2,
 N'Netflix',  N'Gói xem phim tháng 1', NULL, '2026-01-05', '2026-01-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Pharmacy
(10022, 1, 104, 19, 120000, 'VND', 120000, 1.0, 'EXPENSE', 0, NULL,
 N'Nhà thuốc Long Châu', N'Mua thuốc cảm cúm', NULL, '2026-01-11', '2026-01-11',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

-- Water
(10023, 1, 101, 24, 80000, 'VND', 80000, 1.0, 'EXPENSE', 0, NULL,
 N'Lavie / Đại lý nước', N'Nước uống tháng 1', NULL, '2026-01-15', '2026-01-15',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Shopping
(10024, 1, 103, 6,  550000, 'VND', 550000, 1.0, 'EXPENSE', 0, NULL,
 N'Uniqlo Crescent Mall', N'Áo mùa đông', NULL, '2026-01-18', '2026-01-18',
 10.7320, 106.7220, N'Ho Chi Minh City', 'VN', 1, 0),

-- Savings transfer
(10025, 1, 101, 10, 3000000, 'VND', 3000000, 1.0, 'TRANSFER', 0, NULL,
 N'Techcombank',  N'Chuyển tiết kiệm tháng 1', NULL, '2026-01-25', '2026-01-25',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- ===========================================================
-- USER 1 — Feb 2026
-- ===========================================================

-- INCOME
(10026, 1, 101, 11, 22000000, 'VND', 22000000, 1.0, 'INCOME', 0, NULL,
 N'Công ty ABC', N'Lương tháng 2/2026', NULL, '2026-02-05', '2026-02-05',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

-- Bonus Tết
(10027, 1, 101, 11, 5000000, 'VND', 5000000, 1.0, 'INCOME', 0, NULL,
 N'Công ty ABC', N'Thưởng Tết 2026', NULL, '2026-02-01', '2026-02-01',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Fixed expenses repeat
(10028, 1, 101, 12, 6000000, 'VND', 6000000, 1.0, 'EXPENSE', 1, 1,
 N'Chủ nhà Quận 7', N'Tiền thuê nhà tháng 2', NULL, '2026-02-01', '2026-02-01',
 10.7320, 106.7220, N'Ho Chi Minh City', 'VN', 1, 0),

(10029, 1, 101, 23, 265000, 'VND', 265000, 1.0, 'EXPENSE', 1, 3,
 N'FPT Telecom', N'Internet tháng 2', NULL, '2026-02-03', '2026-02-03',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10030, 1, 101, 22, 390000, 'VND', 390000, 1.0, 'EXPENSE', 0, NULL,
 N'EVN', N'Tiền điện tháng 2', NULL, '2026-02-04', '2026-02-04',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10031, 1, 101, 20, 200000, 'VND', 200000, 1.0, 'EXPENSE', 1, 4,
 N'California Fitness', N'Phí tháng gym', NULL, '2026-02-02', '2026-02-02',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10032, 1, 101, 21, 220000, 'VND', 220000, 1.0, 'EXPENSE', 1, 2,
 N'Netflix', N'Gói xem phim tháng 2', NULL, '2026-02-05', '2026-02-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Groceries Feb (Tết period: higher spending)
(10033, 1, 101, 14, 1200000, 'VND', 1200000, 1.0, 'EXPENSE', 0, NULL,
 N'Annam Gourmet', N'Mua sắm Tết', NULL, '2026-02-07', '2026-02-07',
 10.7816, 106.6981, N'Ho Chi Minh City', 'VN', 1, 0),

(10034, 1, 101, 14, 900000, 'VND', 900000, 1.0, 'EXPENSE', 0, NULL,
 N'VinMart', N'Mua sắm tạp hóa', NULL, '2026-02-14', '2026-02-14',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10035, 1, 101, 14, 780000, 'VND', 780000, 1.0, 'EXPENSE', 0, NULL,
 N'Co.opmart', N'Mua sắm tạp hóa tuần 3', NULL, '2026-02-21', '2026-02-21',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Restaurants Feb
(10036, 1, 103, 15, 850000, 'VND', 850000, 1.0, 'EXPENSE', 0, NULL,
 N'Nhà hàng Hoa Sen', N'Ăn tiệc Tết gia đình', NULL, '2026-02-09', '2026-02-09',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

(10037, 1, 101, 15, 320000, 'VND', 320000, 1.0, 'EXPENSE', 0, NULL,
 N'Bún Bò Huế Gia Hội', N'Ăn tối', NULL, '2026-02-16', '2026-02-16',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Coffee Feb
(10038, 1, 104, 16, 60000, 'VND', 60000, 1.0, 'EXPENSE', 0, NULL,
 N'Highlands Coffee', N'Cà phê sáng', NULL, '2026-02-10', '2026-02-10',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10039, 1, 104, 16, 90000, 'VND', 90000, 1.0, 'EXPENSE', 0, NULL,
 N'The Coffee House', N'Cà phê chiều', NULL, '2026-02-17', '2026-02-17',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Shopping Feb (Tết)
(10040, 1, 103, 6,  1800000, 'VND', 1800000, 1.0, 'EXPENSE', 0, NULL,
 N'Zara Vincom', N'Quần áo Tết', NULL, '2026-02-06', '2026-02-06',
 10.7936, 106.7220, N'Ho Chi Minh City', 'VN', 1, 0),

-- Savings transfer Feb
(10041, 1, 101, 10, 4000000, 'VND', 4000000, 1.0, 'TRANSFER', 0, NULL,
 N'Techcombank', N'Chuyển tiết kiệm tháng 2', NULL, '2026-02-25', '2026-02-25',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- ===========================================================
-- USER 1 — Mar 2026
-- ===========================================================

-- INCOME
(10042, 1, 101, 11, 22000000, 'VND', 22000000, 1.0, 'INCOME', 0, NULL,
 N'Công ty ABC', N'Lương tháng 3/2026', NULL, '2026-03-05', '2026-03-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Freelance income
(10043, 1, 101, 11, 3500000, 'VND', 3500000, 1.0, 'INCOME', 0, NULL,
 N'Client XYZ', N'Thu nhập freelance thiết kế', NULL, '2026-03-12', '2026-03-12',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Fixed expenses Mar
(10044, 1, 101, 12, 6000000, 'VND', 6000000, 1.0, 'EXPENSE', 1, 1,
 N'Chủ nhà Quận 7', N'Tiền thuê nhà tháng 3', NULL, '2026-03-01', '2026-03-01',
 10.7320, 106.7220, N'Ho Chi Minh City', 'VN', 1, 0),

(10045, 1, 101, 23, 265000, 'VND', 265000, 1.0, 'EXPENSE', 1, 3,
 N'FPT Telecom', N'Internet tháng 3', NULL, '2026-03-03', '2026-03-03',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10046, 1, 101, 22, 430000, 'VND', 430000, 1.0, 'EXPENSE', 0, NULL,
 N'EVN', N'Tiền điện tháng 3', NULL, '2026-03-04', '2026-03-04',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10047, 1, 101, 20, 200000, 'VND', 200000, 1.0, 'EXPENSE', 1, 4,
 N'California Fitness', N'Phí tháng gym', NULL, '2026-03-02', '2026-03-02',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10048, 1, 101, 21, 220000, 'VND', 220000, 1.0, 'EXPENSE', 1, 2,
 N'Netflix', N'Gói xem phim tháng 3', NULL, '2026-03-05', '2026-03-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Groceries Mar
(10049, 1, 101, 14, 820000, 'VND', 820000, 1.0, 'EXPENSE', 0, NULL,
 N'VinMart', N'Tạp hóa tuần 1', NULL, '2026-03-07', '2026-03-07',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10050, 1, 101, 14, 750000, 'VND', 750000, 1.0, 'EXPENSE', 0, NULL,
 N'Co.opmart', N'Tạp hóa tuần 2', NULL, '2026-03-14', '2026-03-14',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10051, 1, 101, 14, 870000, 'VND', 870000, 1.0, 'EXPENSE', 0, NULL,
 N'BigC', N'Tạp hóa tuần 3', NULL, '2026-03-21', '2026-03-21',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Restaurants Mar
(10052, 1, 103, 15, 280000, 'VND', 280000, 1.0, 'EXPENSE', 0, NULL,
 N'Bánh Xèo Mười Xiềm', N'Ăn tối', NULL, '2026-03-08', '2026-03-08',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10053, 1, 103, 15, 420000, 'VND', 420000, 1.0, 'EXPENSE', 0, NULL,
 N'Nhà hàng Ngon', N'Ăn tối với đối tác', NULL, '2026-03-15', '2026-03-15',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Coffee Mar
(10054, 1, 104, 16, 70000, 'VND', 70000, 1.0, 'EXPENSE', 0, NULL,
 N'Highlands Coffee', N'Cà phê sáng', NULL, '2026-03-09', '2026-03-09',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(10055, 1, 104, 16, 65000, 'VND', 65000, 1.0, 'EXPENSE', 0, NULL,
 N'Phúc Long', N'Cà phê chiều', NULL, '2026-03-16', '2026-03-16',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Grab Mar
(10056, 1, 103, 18, 55000, 'VND', 55000, 1.0, 'EXPENSE', 0, NULL,
 N'Grab', N'Đi họp', NULL, '2026-03-11', '2026-03-11',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Health Mar
(10057, 1, 104, 19, 85000, 'VND', 85000, 1.0, 'EXPENSE', 0, NULL,
 N'Nhà thuốc FPT Long Châu', N'Vitamin tổng hợp', NULL, '2026-03-13', '2026-03-13',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Shopping Mar
(10058, 1, 103, 6,  450000, 'VND', 450000, 1.0, 'EXPENSE', 0, NULL,
 N'Shopee', N'Mua phụ kiện laptop online', NULL, '2026-03-10', '2026-03-10',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Savings transfer Mar
(10059, 1, 101, 10, 3500000, 'VND', 3500000, 1.0, 'TRANSFER', 0, NULL,
 N'Techcombank', N'Chuyển tiết kiệm tháng 3', NULL, '2026-03-25', '2026-03-25',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- ===========================================================
-- USER 2 — tran_thi_bich (Jan - Mar 2026)
-- ===========================================================

-- INCOME Jan
(20001, 2, 201, 11, 15000000, 'VND', 15000000, 1.0, 'INCOME', 0, NULL,
 N'Trường THPT Nguyễn Du', N'Lương giáo viên tháng 1', NULL, '2026-01-05', '2026-01-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Fixed Jan
(20002, 2, 201, 34, 180000, 'VND', 180000, 1.0, 'EXPENSE', 1, 5,
 N'FPT Telecom', N'Internet tháng 1', NULL, '2026-01-03', '2026-01-03',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(20003, 2, 201, 35, 450000, 'VND', 450000, 1.0, 'EXPENSE', 1, 6,
 N'Coursera', N'Học phí online tháng 1', NULL, '2026-01-05', '2026-01-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Groceries Jan
(20004, 2, 201, 26, 650000, 'VND', 650000, 1.0, 'EXPENSE', 0, NULL,
 N'Co.opmart Q.Bình Thạnh', N'Tạp hóa tuần 1', NULL, '2026-01-06', '2026-01-06',
 10.8120, 106.7040, N'Ho Chi Minh City', 'VN', 1, 0),

(20005, 2, 201, 26, 580000, 'VND', 580000, 1.0, 'EXPENSE', 0, NULL,
 N'VinMart', N'Tạp hóa tuần 2', NULL, '2026-01-13', '2026-01-13',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(20006, 2, 201, 26, 710000, 'VND', 710000, 1.0, 'EXPENSE', 0, NULL,
 N'Lotte Mart', N'Tạp hóa tuần 3', NULL, '2026-01-20', '2026-01-20',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Coffee Jan
(20007, 2, 203, 27, 55000, 'VND', 55000, 1.0, 'EXPENSE', 0, NULL,
 N'Phúc Long', N'Cà phê sáng', NULL, '2026-01-08', '2026-01-08',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(20008, 2, 203, 27, 65000, 'VND', 65000, 1.0, 'EXPENSE', 0, NULL,
 N'Highlands Coffee', N'Cà phê sau giờ dạy', NULL, '2026-01-15', '2026-01-15',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Fuel Jan
(20009, 2, 201, 28, 180000, 'VND', 180000, 1.0, 'EXPENSE', 0, NULL,
 N'Petrolimex', N'Đổ xăng xe máy', NULL, '2026-01-09', '2026-01-09',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(20010, 2, 201, 28, 200000, 'VND', 200000, 1.0, 'EXPENSE', 0, NULL,
 N'Petrolimex', N'Đổ xăng xe máy', NULL, '2026-01-22', '2026-01-22',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Shopping Jan
(20011, 2, 203, 29, 850000, 'VND', 850000, 1.0, 'EXPENSE', 0, NULL,
 N'Zara Vincom Đồng Khởi', N'Mua áo blouse', NULL, '2026-01-11', '2026-01-11',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

(20012, 2, 203, 30, 420000, 'VND', 420000, 1.0, 'EXPENSE', 0, NULL,
 N'The Face Shop', N'Mặt nạ và kem dưỡng', NULL, '2026-01-18', '2026-01-18',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Electricity Jan
(20013, 2, 201, 31, 350000, 'VND', 350000, 1.0, 'EXPENSE', 0, NULL,
 N'EVN', N'Tiền điện tháng 1', NULL, '2026-01-04', '2026-01-04',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- INCOME Feb
(20014, 2, 201, 11, 15000000, 'VND', 15000000, 1.0, 'INCOME', 0, NULL,
 N'Trường THPT Nguyễn Du', N'Lương giáo viên tháng 2', NULL, '2026-02-05', '2026-02-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Fixed Feb
(20015, 2, 201, 34, 180000, 'VND', 180000, 1.0, 'EXPENSE', 1, 5,
 N'FPT Telecom', N'Internet tháng 2', NULL, '2026-02-03', '2026-02-03',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(20016, 2, 201, 35, 450000, 'VND', 450000, 1.0, 'EXPENSE', 1, 6,
 N'Coursera', N'Học phí online tháng 2', NULL, '2026-02-05', '2026-02-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Groceries Feb (Tết)
(20017, 2, 201, 26, 950000, 'VND', 950000, 1.0, 'EXPENSE', 0, NULL,
 N'Annam Gourmet', N'Sắm Tết', NULL, '2026-02-07', '2026-02-07',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(20018, 2, 201, 26, 620000, 'VND', 620000, 1.0, 'EXPENSE', 0, NULL,
 N'Co.opmart', N'Tạp hóa tuần 3', NULL, '2026-02-18', '2026-02-18',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Shopping Feb (Tết)
(20019, 2, 203, 29, 1200000, 'VND', 1200000, 1.0, 'EXPENSE', 0, NULL,
 N'Shopee', N'Mua váy Tết online', NULL, '2026-02-04', '2026-02-04',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(20020, 2, 203, 30, 680000, 'VND', 680000, 1.0, 'EXPENSE', 0, NULL,
 N'Innisfree', N'Bộ dưỡng da mới', NULL, '2026-02-13', '2026-02-13',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- INCOME Mar
(20021, 2, 201, 11, 15000000, 'VND', 15000000, 1.0, 'INCOME', 0, NULL,
 N'Trường THPT Nguyễn Du', N'Lương giáo viên tháng 3', NULL, '2026-03-05', '2026-03-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Fixed Mar
(20022, 2, 201, 34, 180000, 'VND', 180000, 1.0, 'EXPENSE', 1, 5,
 N'FPT Telecom', N'Internet tháng 3', NULL, '2026-03-03', '2026-03-03',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(20023, 2, 201, 35, 450000, 'VND', 450000, 1.0, 'EXPENSE', 1, 6,
 N'Coursera', N'Học phí online tháng 3', NULL, '2026-03-05', '2026-03-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Groceries Mar
(20024, 2, 201, 26, 680000, 'VND', 680000, 1.0, 'EXPENSE', 0, NULL,
 N'Co.opmart', N'Tạp hóa tuần 1', NULL, '2026-03-07', '2026-03-07',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(20025, 2, 201, 26, 590000, 'VND', 590000, 1.0, 'EXPENSE', 0, NULL,
 N'VinMart', N'Tạp hóa tuần 2', NULL, '2026-03-14', '2026-03-14',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Fuel Mar
(20026, 2, 201, 28, 190000, 'VND', 190000, 1.0, 'EXPENSE', 0, NULL,
 N'Petrolimex', N'Đổ xăng xe máy', NULL, '2026-03-10', '2026-03-10',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Shopping Mar
(20027, 2, 203, 29, 750000, 'VND', 750000, 1.0, 'EXPENSE', 0, NULL,
 N'H&M Vincom', N'Mua quần jeans', NULL, '2026-03-08', '2026-03-08',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Electricity Mar
(20028, 2, 201, 31, 380000, 'VND', 380000, 1.0, 'EXPENSE', 0, NULL,
 N'EVN', N'Tiền điện tháng 3', NULL, '2026-03-04', '2026-03-04',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- ===========================================================
-- USER 3 — le_minh_khoa (Jan - Mar 2026)
-- ===========================================================

-- INCOME Jan
(30001, 3, 301, 11, 35000000, 'VND', 35000000, 1.0, 'INCOME', 0, NULL,
 N'Công ty Tech Saigon', N'Lương kỹ sư phần mềm tháng 1', NULL, '2026-01-05', '2026-01-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Fixed Jan
(30002, 3, 301, 37, 7500000, 'VND', 7500000, 1.0, 'EXPENSE', 1, 7,
 N'Chủ nhà Quận 1', N'Thuê căn hộ tháng 1', NULL, '2026-01-01', '2026-01-01',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

(30003, 3, 301, 43, 265000, 'VND', 265000, 1.0, 'EXPENSE', 1, 8,
 N'Viettel', N'Internet tháng 1', NULL, '2026-01-03', '2026-01-03',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30004, 3, 301, 42, 199000, 'VND', 199000, 1.0, 'EXPENSE', 1, 9,
 N'Spotify', N'Spotify Premium tháng 1', NULL, '2026-01-05', '2026-01-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Electricity Jan
(30005, 3, 301, 41, 550000, 'VND', 550000, 1.0, 'EXPENSE', 0, NULL,
 N'EVN', N'Tiền điện tháng 1', NULL, '2026-01-04', '2026-01-04',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Groceries Jan
(30006, 3, 301, 38, 980000, 'VND', 980000, 1.0, 'EXPENSE', 0, NULL,
 N'Annam Gourmet', N'Tạp hóa chất lượng cao', NULL, '2026-01-06', '2026-01-06',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

(30007, 3, 301, 38, 870000, 'VND', 870000, 1.0, 'EXPENSE', 0, NULL,
 N'VinMart+', N'Tạp hóa tuần 2', NULL, '2026-01-13', '2026-01-13',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30008, 3, 301, 38, 920000, 'VND', 920000, 1.0, 'EXPENSE', 0, NULL,
 N'Co.opmart', N'Tạp hóa tuần 3', NULL, '2026-01-20', '2026-01-20',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Restaurants Jan
(30009, 3, 303, 39, 650000, 'VND', 650000, 1.0, 'EXPENSE', 0, NULL,
 N'Nhà hàng Cửu Long', N'Ăn tối cùng đội nhóm', NULL, '2026-01-08', '2026-01-08',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

(30010, 3, 303, 39, 420000, 'VND', 420000, 1.0, 'EXPENSE', 0, NULL,
 N'The Racha Room', N'Ăn tối', NULL, '2026-01-15', '2026-01-15',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30011, 3, 303, 39, 280000, 'VND', 280000, 1.0, 'EXPENSE', 0, NULL,
 N'Phở Thìn', N'Ăn trưa', NULL, '2026-01-22', '2026-01-22',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Grab Jan
(30012, 3, 303, 40, 85000, 'VND', 85000, 1.0, 'EXPENSE', 0, NULL,
 N'Grab', N'Đi làm', NULL, '2026-01-09', '2026-01-09',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30013, 3, 303, 40, 95000, 'VND', 95000, 1.0, 'EXPENSE', 0, NULL,
 N'Grab', N'Đi họp ngoài văn phòng', NULL, '2026-01-16', '2026-01-16',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Emergency Fund savings Jan
(30014, 3, 301, 44, 5000000, 'VND', 5000000, 1.0, 'TRANSFER', 0, NULL,
 N'Shinhan Bank', N'Tiết kiệm khẩn cấp tháng 1', NULL, '2026-01-25', '2026-01-25',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- INCOME Feb
(30015, 3, 301, 11, 35000000, 'VND', 35000000, 1.0, 'INCOME', 0, NULL,
 N'Công ty Tech Saigon', N'Lương kỹ sư phần mềm tháng 2', NULL, '2026-02-05', '2026-02-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Fixed Feb
(30016, 3, 301, 37, 7500000, 'VND', 7500000, 1.0, 'EXPENSE', 1, 7,
 N'Chủ nhà Quận 1', N'Thuê căn hộ tháng 2', NULL, '2026-02-01', '2026-02-01',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30017, 3, 301, 43, 265000, 'VND', 265000, 1.0, 'EXPENSE', 1, 8,
 N'Viettel', N'Internet tháng 2', NULL, '2026-02-03', '2026-02-03',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30018, 3, 301, 42, 199000, 'VND', 199000, 1.0, 'EXPENSE', 1, 9,
 N'Spotify', N'Spotify Premium tháng 2', NULL, '2026-02-05', '2026-02-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Electricity Feb
(30019, 3, 301, 41, 500000, 'VND', 500000, 1.0, 'EXPENSE', 0, NULL,
 N'EVN', N'Tiền điện tháng 2', NULL, '2026-02-04', '2026-02-04',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Groceries Feb (Tết)
(30020, 3, 301, 38, 1500000, 'VND', 1500000, 1.0, 'EXPENSE', 0, NULL,
 N'Annam Gourmet', N'Mua sắm Tết cao cấp', NULL, '2026-02-07', '2026-02-07',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30021, 3, 301, 38, 880000, 'VND', 880000, 1.0, 'EXPENSE', 0, NULL,
 N'VinMart+', N'Tạp hóa tuần 3', NULL, '2026-02-18', '2026-02-18',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Restaurants Feb (Tết)
(30022, 3, 303, 39, 1200000, 'VND', 1200000, 1.0, 'EXPENSE', 0, NULL,
 N'Rex Hotel Restaurant', N'Tiệc Tết công ty', NULL, '2026-02-09', '2026-02-09',
 10.7769, 106.7009, N'Ho Chi Minh City', 'VN', 1, 0),

(30023, 3, 303, 39, 580000, 'VND', 580000, 1.0, 'EXPENSE', 0, NULL,
 N'Bún Đậu Mắm Tôm', N'Ăn cùng bạn bè', NULL, '2026-02-15', '2026-02-15',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Emergency Fund savings Feb
(30024, 3, 301, 44, 5000000, 'VND', 5000000, 1.0, 'TRANSFER', 0, NULL,
 N'Shinhan Bank', N'Tiết kiệm khẩn cấp tháng 2', NULL, '2026-02-25', '2026-02-25',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- INCOME Mar
(30025, 3, 301, 11, 35000000, 'VND', 35000000, 1.0, 'INCOME', 0, NULL,
 N'Công ty Tech Saigon', N'Lương kỹ sư phần mềm tháng 3', NULL, '2026-03-05', '2026-03-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Freelance income Mar
(30026, 3, 301, 11, 8000000, 'VND', 8000000, 1.0, 'INCOME', 0, NULL,
 N'Startup ABC', N'Tư vấn kỹ thuật', NULL, '2026-03-20', '2026-03-20',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Fixed Mar
(30027, 3, 301, 37, 7500000, 'VND', 7500000, 1.0, 'EXPENSE', 1, 7,
 N'Chủ nhà Quận 1', N'Thuê căn hộ tháng 3', NULL, '2026-03-01', '2026-03-01',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30028, 3, 301, 43, 265000, 'VND', 265000, 1.0, 'EXPENSE', 1, 8,
 N'Viettel', N'Internet tháng 3', NULL, '2026-03-03', '2026-03-03',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30029, 3, 301, 42, 199000, 'VND', 199000, 1.0, 'EXPENSE', 1, 9,
 N'Spotify', N'Spotify Premium tháng 3', NULL, '2026-03-05', '2026-03-05',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Electricity Mar
(30030, 3, 301, 41, 580000, 'VND', 580000, 1.0, 'EXPENSE', 0, NULL,
 N'EVN', N'Tiền điện tháng 3', NULL, '2026-03-04', '2026-03-04',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Groceries Mar
(30031, 3, 301, 38, 950000, 'VND', 950000, 1.0, 'EXPENSE', 0, NULL,
 N'VinMart+', N'Tạp hóa tuần 1', NULL, '2026-03-07', '2026-03-07',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30032, 3, 301, 38, 880000, 'VND', 880000, 1.0, 'EXPENSE', 0, NULL,
 N'Co.opmart', N'Tạp hóa tuần 2', NULL, '2026-03-14', '2026-03-14',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30033, 3, 301, 38, 910000, 'VND', 910000, 1.0, 'EXPENSE', 0, NULL,
 N'Annam Gourmet', N'Tạp hóa tuần 3', NULL, '2026-03-21', '2026-03-21',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Restaurants Mar
(30034, 3, 303, 39, 520000, 'VND', 520000, 1.0, 'EXPENSE', 0, NULL,
 N'Nhà hàng Ngon', N'Ăn tối', NULL, '2026-03-08', '2026-03-08',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

(30035, 3, 303, 39, 350000, 'VND', 350000, 1.0, 'EXPENSE', 0, NULL,
 N'Cơm Niêu Sài Gòn', N'Ăn trưa làm việc', NULL, '2026-03-17', '2026-03-17',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Grab Mar
(30036, 3, 303, 40, 75000, 'VND', 75000, 1.0, 'EXPENSE', 0, NULL,
 N'Grab', N'Đi họp khách hàng', NULL, '2026-03-11', '2026-03-11',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0),

-- Emergency Fund savings Mar
(30037, 3, 301, 44, 6000000, 'VND', 6000000, 1.0, 'TRANSFER', 0, NULL,
 N'Shinhan Bank', N'Tiết kiệm khẩn cấp tháng 3', NULL, '2026-03-25', '2026-03-25',
 NULL, NULL, N'Ho Chi Minh City', 'VN', 1, 0);

-- ============================================================
-- SECTION 8: TRANSACTION TAGS
-- ============================================================

INSERT INTO transaction_tags (transaction_id, tags_id)
VALUES
-- User 1: essential / recurring tags
(10002, 3), -- rent → essential
(10002, 2), -- rent → recurring
(10003, 2), -- internet → recurring
(10020, 2), -- gym → recurring
(10021, 2), -- netflix → recurring
(10005, 3), -- groceries → essential
(10006, 3),
(10007, 3),
(10008, 3),
(10024, 4), -- Uniqlo → impulse
(10040, 4), -- Zara Feb → impulse
(10058, 5), -- Shopee online → online
(10021, 5), -- Netflix → online

-- User 2: recurring / essential / weekend
(20002, 6), -- internet → recurring
(20003, 6), -- coursera → recurring
(20003, 9), -- coursera → online
(20004, 7), -- groceries → essential
(20005, 7),
(20006, 7),
(20011, 8), -- shopping → weekend
(20012, 8),
(20019, 9), -- shopee → online

-- User 3: recurring / essential / work
(30002, 10), -- rent → recurring
(30003, 10), -- internet → recurring
(30004, 10), -- spotify → recurring
(30006, 11), -- groceries → essential
(30007, 11),
(30008, 11),
(30009, 12), -- team dinner → work
(30013, 12), -- grab to meeting → work
(30022, 12); -- company dinner → work

-- ============================================================
-- SECTION 9: DAILY SUMMARIES
-- (Manual seed; normally auto-populated by trigger/procedure)
-- ============================================================

-- User 1 — Jan 2026 key dates
INSERT INTO daily_summaries (summary_id, user_id, summary_date, total_expense, total_income, net_amount)
VALUES
(1,  1, '2026-01-01', 6000000,    0,          -6000000),
(2,  1, '2026-01-02', 200000,     0,          -200000),
(3,  1, '2026-01-03', 265000,     0,          -265000),
(4,  1, '2026-01-04', 410000,     0,          -410000),
(5,  1, '2026-01-05', 220000,     22000000,    21780000),
(6,  1, '2026-01-06', 850000,     0,          -850000),
(7,  1, '2026-01-07', 180000,     0,          -180000),
(8,  1, '2026-01-08', 65000,      0,          -65000),
(9,  1, '2026-01-09', 45000,      0,          -45000),
(10, 1, '2026-01-10', 450000,     0,          -450000),
(11, 1, '2026-01-11', 120000,     0,          -120000),
(12, 1, '2026-01-12', 75000,      0,          -75000),
(13, 1, '2026-01-13', 720000,     0,          -720000),
(14, 1, '2026-01-14', 220000,     0,          -220000),
(15, 1, '2026-01-15', 80000,      0,          -80000),
(16, 1, '2026-01-16', 62000,      0,          -62000),
(17, 1, '2026-01-17', 380000,     0,          -380000),
(18, 1, '2026-01-18', 550000,     0,          -550000),
(19, 1, '2026-01-19', 55000,      0,          -55000),
(20, 1, '2026-01-20', 900000,     0,          -900000),
(21, 1, '2026-01-22', 150000,     0,          -150000),
(22, 1, '2026-01-23', 80000,      0,          -80000),
(23, 1, '2026-01-25', 3000000,    0,          -3000000),
(24, 1, '2026-01-27', 650000,     0,          -650000),

-- User 1 — Feb 2026 key dates
(25, 1, '2026-02-01', 6000000,    5000000,    -1000000),
(26, 1, '2026-02-02', 200000,     0,          -200000),
(27, 1, '2026-02-03', 265000,     0,          -265000),
(28, 1, '2026-02-04', 390000,     0,          -390000),
(29, 1, '2026-02-05', 220000,     22000000,    21780000),
(30, 1, '2026-02-06', 1800000,    0,          -1800000),
(31, 1, '2026-02-07', 1200000,    0,          -1200000),
(32, 1, '2026-02-09', 850000,     0,          -850000),
(33, 1, '2026-02-10', 60000,      0,          -60000),
(34, 1, '2026-02-14', 900000,     0,          -900000),
(35, 1, '2026-02-16', 320000,     0,          -320000),
(36, 1, '2026-02-17', 90000,      0,          -90000),
(37, 1, '2026-02-21', 780000,     0,          -780000),
(38, 1, '2026-02-25', 4000000,    0,          -4000000),

-- User 1 — Mar 2026 key dates
(39, 1, '2026-03-01', 6000000,    0,          -6000000),
(40, 1, '2026-03-02', 200000,     0,          -200000),
(41, 1, '2026-03-03', 265000,     0,          -265000),
(42, 1, '2026-03-04', 430000,     0,          -430000),
(43, 1, '2026-03-05', 220000,     22000000,    21780000),
(44, 1, '2026-03-07', 820000,     0,          -820000),
(45, 1, '2026-03-08', 280000,     0,          -280000),
(46, 1, '2026-03-09', 70000,      0,          -70000),
(47, 1, '2026-03-10', 450000,     0,          -450000),
(48, 1, '2026-03-11', 55000,      0,          -55000),
(49, 1, '2026-03-12', 0,          3500000,    3500000),
(50, 1, '2026-03-13', 85000,      0,          -85000),
(51, 1, '2026-03-14', 750000,     0,          -750000),
(52, 1, '2026-03-15', 420000,     0,          -420000),
(53, 1, '2026-03-16', 65000,      0,          -65000),
(54, 1, '2026-03-21', 870000,     0,          -870000),
(55, 1, '2026-03-25', 3500000,    0,          -3500000),

-- User 2 — selected dates
(56, 2, '2026-01-03', 180000,  0,           -180000),
(57, 2, '2026-01-04', 350000,  0,           -350000),
(58, 2, '2026-01-05', 450000,  15000000,    14550000),
(59, 2, '2026-01-06', 650000,  0,           -650000),
(60, 2, '2026-01-08', 55000,   0,           -55000),
(61, 2, '2026-01-09', 180000,  0,           -180000),
(62, 2, '2026-01-11', 850000,  0,           -850000),
(63, 2, '2026-01-13', 580000,  0,           -580000),
(64, 2, '2026-01-15', 65000,   0,           -65000),
(65, 2, '2026-01-18', 420000,  0,           -420000),
(66, 2, '2026-01-20', 710000,  0,           -710000),
(67, 2, '2026-01-22', 200000,  0,           -200000),

-- User 3 — selected dates
(68, 3, '2026-01-01', 7500000, 0,           -7500000),
(69, 3, '2026-01-03', 265000,  0,           -265000),
(70, 3, '2026-01-04', 550000,  0,           -550000),
(71, 3, '2026-01-05', 199000,  35000000,    34801000),
(72, 3, '2026-01-06', 980000,  0,           -980000),
(73, 3, '2026-01-08', 650000,  0,           -650000),
(74, 3, '2026-01-09', 85000,   0,           -85000),
(75, 3, '2026-01-13', 870000,  0,           -870000),
(76, 3, '2026-01-15', 420000,  0,           -420000),
(77, 3, '2026-01-16', 95000,   0,           -95000),
(78, 3, '2026-01-20', 920000,  0,           -920000),
(79, 3, '2026-01-22', 280000,  0,           -280000),
(80, 3, '2026-01-25', 5000000, 0,           -5000000);

-- ============================================================
-- SECTION 10: MONTHLY CATEGORY TOTALS
-- ============================================================

INSERT INTO monthly_category_totals
    (mc_total_id, user_id, category_id, year, month, total_amount, transaction_count, avg_transaction)
VALUES
-- User 1 — Jan 2026
(1,  1, 12,  2026, 1, 6000000,  1, 6000000.00),   -- Rent
(2,  1, 23,  2026, 1, 265000,   1, 265000.00),     -- Internet
(3,  1, 22,  2026, 1, 410000,   1, 410000.00),     -- Electricity
(4,  1, 14,  2026, 1, 3120000,  4, 780000.00),     -- Groceries
(5,  1, 15,  2026, 1, 1380000,  5, 276000.00),     -- Restaurants
(6,  1, 16,  2026, 1, 275000,   4, 68750.00),      -- Coffee
(7,  1, 18,  2026, 1, 107000,   2, 53500.00),      -- Grab
(8,  1, 20,  2026, 1, 200000,   1, 200000.00),     -- Gym
(9,  1, 21,  2026, 1, 220000,   1, 220000.00),     -- Netflix
(10, 1, 19,  2026, 1, 120000,   1, 120000.00),     -- Pharmacy
(11, 1, 24,  2026, 1, 80000,    1, 80000.00),      -- Water
(12, 1, 6,   2026, 1, 550000,   1, 550000.00),     -- Shopping
(13, 1, 10,  2026, 1, 3000000,  1, 3000000.00),    -- Savings
(14, 1, 11,  2026, 1, 22000000, 1, 22000000.00),   -- Income

-- User 1 — Feb 2026
(15, 1, 12,  2026, 2, 6000000,  1, 6000000.00),
(16, 1, 23,  2026, 2, 265000,   1, 265000.00),
(17, 1, 22,  2026, 2, 390000,   1, 390000.00),
(18, 1, 14,  2026, 2, 3880000,  3, 1293333.33),
(19, 1, 15,  2026, 2, 1170000,  2, 585000.00),
(20, 1, 16,  2026, 2, 150000,   2, 75000.00),
(21, 1, 20,  2026, 2, 200000,   1, 200000.00),
(22, 1, 21,  2026, 2, 220000,   1, 220000.00),
(23, 1, 6,   2026, 2, 1800000,  1, 1800000.00),
(24, 1, 10,  2026, 2, 4000000,  1, 4000000.00),
(25, 1, 11,  2026, 2, 27000000, 2, 13500000.00),

-- User 1 — Mar 2026
(26, 1, 12,  2026, 3, 6000000,  1, 6000000.00),
(27, 1, 23,  2026, 3, 265000,   1, 265000.00),
(28, 1, 22,  2026, 3, 430000,   1, 430000.00),
(29, 1, 14,  2026, 3, 2440000,  3, 813333.33),
(30, 1, 15,  2026, 3, 700000,   2, 350000.00),
(31, 1, 16,  2026, 3, 135000,   2, 67500.00),
(32, 1, 18,  2026, 3, 55000,    1, 55000.00),
(33, 1, 20,  2026, 3, 200000,   1, 200000.00),
(34, 1, 21,  2026, 3, 220000,   1, 220000.00),
(35, 1, 19,  2026, 3, 85000,    1, 85000.00),
(36, 1, 6,   2026, 3, 450000,   1, 450000.00),
(37, 1, 10,  2026, 3, 3500000,  1, 3500000.00),
(38, 1, 11,  2026, 3, 25500000, 2, 12750000.00),

-- User 2 — Jan 2026
(39, 2, 34,  2026, 1, 180000,   1, 180000.00),
(40, 2, 35,  2026, 1, 450000,   1, 450000.00),
(41, 2, 26,  2026, 1, 1940000,  3, 646666.67),
(42, 2, 27,  2026, 1, 120000,   2, 60000.00),
(43, 2, 28,  2026, 1, 380000,   2, 190000.00),
(44, 2, 29,  2026, 1, 850000,   1, 850000.00),
(45, 2, 30,  2026, 1, 420000,   1, 420000.00),
(46, 2, 31,  2026, 1, 350000,   1, 350000.00),
(47, 2, 11,  2026, 1, 15000000, 1, 15000000.00),

-- User 2 — Feb 2026
(48, 2, 34,  2026, 2, 180000,   1, 180000.00),
(49, 2, 35,  2026, 2, 450000,   1, 450000.00),
(50, 2, 26,  2026, 2, 1570000,  2, 785000.00),
(51, 2, 29,  2026, 2, 1200000,  1, 1200000.00),
(52, 2, 30,  2026, 2, 680000,   1, 680000.00),
(53, 2, 11,  2026, 2, 15000000, 1, 15000000.00),

-- User 2 — Mar 2026
(54, 2, 34,  2026, 3, 180000,   1, 180000.00),
(55, 2, 35,  2026, 3, 450000,   1, 450000.00),
(56, 2, 26,  2026, 3, 1270000,  2, 635000.00),
(57, 2, 28,  2026, 3, 190000,   1, 190000.00),
(58, 2, 29,  2026, 3, 750000,   1, 750000.00),
(59, 2, 31,  2026, 3, 380000,   1, 380000.00),
(60, 2, 11,  2026, 3, 15000000, 1, 15000000.00),

-- User 3 — Jan 2026
(61, 3, 37,  2026, 1, 7500000,  1, 7500000.00),
(62, 3, 43,  2026, 1, 265000,   1, 265000.00),
(63, 3, 42,  2026, 1, 199000,   1, 199000.00),
(64, 3, 41,  2026, 1, 550000,   1, 550000.00),
(65, 3, 38,  2026, 1, 2770000,  3, 923333.33),
(66, 3, 39,  2026, 1, 1350000,  3, 450000.00),
(67, 3, 40,  2026, 1, 180000,   2, 90000.00),
(68, 3, 44,  2026, 1, 5000000,  1, 5000000.00),
(69, 3, 11,  2026, 1, 35000000, 1, 35000000.00),

-- User 3 — Feb 2026
(70, 3, 37,  2026, 2, 7500000,  1, 7500000.00),
(71, 3, 43,  2026, 2, 265000,   1, 265000.00),
(72, 3, 42,  2026, 2, 199000,   1, 199000.00),
(73, 3, 41,  2026, 2, 500000,   1, 500000.00),
(74, 3, 38,  2026, 2, 2380000,  2, 1190000.00),
(75, 3, 39,  2026, 2, 1780000,  2, 890000.00),
(76, 3, 44,  2026, 2, 5000000,  1, 5000000.00),
(77, 3, 11,  2026, 2, 35000000, 1, 35000000.00),

-- User 3 — Mar 2026
(78, 3, 37,  2026, 3, 7500000,  1, 7500000.00),
(79, 3, 43,  2026, 3, 265000,   1, 265000.00),
(80, 3, 42,  2026, 3, 199000,   1, 199000.00),
(81, 3, 41,  2026, 3, 580000,   1, 580000.00),
(82, 3, 38,  2026, 3, 2740000,  3, 913333.33),
(83, 3, 39,  2026, 3, 870000,   2, 435000.00),
(84, 3, 40,  2026, 3, 75000,    1, 75000.00),
(85, 3, 44,  2026, 3, 6000000,  1, 6000000.00),
(86, 3, 11,  2026, 3, 43000000, 2, 21500000.00);

-- ============================================================
-- SECTION 11: FINANCIAL SNAPSHOTS
-- ============================================================

INSERT INTO financial_snapshots (
    snapshot_id, user_id, year, month,
    total_expenses, total_income, net_savings, savings_rate_pct,
    fixed_expense_total, variable_expense_total,
    budget_adherence_pct, overspent_categories, anomaly_flags,
    spending_consistency_score,
    burn_rate, predicted_next_month, months_of_runway)
VALUES
-- User 1 — Jan 2026
(1, 1, 2026, 1,
 12462000, 22000000, 9538000, 43.354,
 6485000,  5977000,
 100.00,
 N'[]',
 N'[]',
 72.50,
 402000.00, 13000000.00, 4.20),

-- User 1 — Feb 2026
(2, 1, 2026, 2,
 14875000, 27000000, 12125000, 44.907,
 6875000,  8000000,
 100.00,
 N'[]',
 N'[{"category":"Food & Dining","score":1.8,"reason":"Tết spending spike +38%"}]',
 65.20,
 531250.00, 13500000.00, 5.10),

-- User 1 — Mar 2026
(3, 1, 2026, 3,
 12280000, 25500000, 13220000, 51.843,
 6915000,  5365000,
 100.00,
 N'[]',
 N'[]',
 78.30,
 396129.00, 12500000.00, 4.80),

-- User 2 — Jan 2026
(4, 2, 2026, 1,
 4690000, 15000000, 10310000, 68.733,
 630000,  4060000,
 100.00,
 N'[]',
 N'[]',
 81.40,
 151290.00, 5000000.00, 8.90),

-- User 2 — Feb 2026
(5, 2, 2026, 2,
 4080000, 15000000, 10920000, 72.800,
 630000,  3450000,
 100.00,
 N'[]',
 N'[{"category":"Shopping","score":1.6,"reason":"Tết clothing spike +41%"}]',
 76.10,
 145714.00, 4800000.00, 9.30),

-- User 2 — Mar 2026
(6, 2, 2026, 3,
 4220000, 15000000, 10780000, 71.867,
 630000,  3590000,
 100.00,
 N'[]',
 N'[]',
 80.60,
 136129.00, 4500000.00, 10.20),

-- User 3 — Jan 2026
(7, 3, 2026, 1,
 17264000, 35000000, 17736000, 50.674,
 7964000,  9300000,
 100.00,
 N'[]',
 N'[]',
 69.80,
 557032.00, 18000000.00, 3.90),

-- User 3 — Feb 2026
(8, 3, 2026, 2,
 17144000, 35000000, 17856000, 51.017,
 7964000,  9180000,
 100.00,
 N'[]',
 N'[{"category":"Food & Dining","score":1.9,"reason":"Tết dining spike +32%"}]',
 62.50,
 612285.00, 18200000.00, 3.70),

-- User 3 — Mar 2026
(9, 3, 2026, 3,
 18229000, 43000000, 24771000, 57.607,
 8544000,  9685000,
 100.00,
 N'[]',
 N'[]',
 74.20,
 588032.00, 18500000.00, 4.50);

-- ============================================================
-- SECTION 12: ANOMALIES
-- ============================================================

INSERT INTO anomalies
    (anomaly_id, user_id, transaction_id, category_id, anomaly_type, severity, description, is_false_positive)
VALUES
-- User 1: Tết Zara spend (Feb) flagged as large transaction
(1, 1, 10040, 6,  'LARGE_TRANSACTION', 'MEDIUM',
 N'Chi tiêu mua sắm 1,800,000 VND — cao hơn 3 lần mức trung bình tháng trước (600,000 VND)', 0),

-- User 1: Tết grocery spike (Feb)
(2, 1, 10033, 14, 'CATEGORY_GROWTH', 'LOW',
 N'Mua tạp hóa tăng 41% so với tháng 1: 1,200,000 VND vs trung bình 780,000 VND', 0),

-- User 2: Shopee online Tết order (Feb) flagged
(3, 2, 20019, 29, 'LARGE_TRANSACTION', 'MEDIUM',
 N'Mua sắm online 1,200,000 VND — cao gấp đôi mức chi tiêu mua sắm thông thường', 0),

-- User 3: Company Tết dinner at Rex Hotel (Feb)
(4, 3, 30022, 39, 'LARGE_TRANSACTION', 'HIGH',
 N'Chi ăn uống 1,200,000 VND — bất thường so với mức trung bình 430,000 VND', 0),

-- User 3: Tết grocery spike (Feb)
(5, 3, 30020, 38, 'CATEGORY_GROWTH', 'MEDIUM',
 N'Tạp hóa cao cấp 1,500,000 VND — tăng 53% so với mức thường (980,000 VND)', 0);

-- ============================================================
-- Re-enable trigger
-- ============================================================

ENABLE TRIGGER after_transaction_upsert ON transactions;
GO

-- ============================================================
-- VERIFICATION QUERIES (run to confirm data integrity)
-- ============================================================

-- Row counts
SELECT 'users'                   AS tbl, COUNT(*) AS rows FROM dbo.users
UNION ALL SELECT 'categories',        COUNT(*) FROM dbo.categories
UNION ALL SELECT 'accounts',          COUNT(*) FROM dbo.accounts
UNION ALL SELECT 'tags',              COUNT(*) FROM tags
UNION ALL SELECT 'recurring_rules',   COUNT(*) FROM recurring_rules
UNION ALL SELECT 'budgets',           COUNT(*) FROM budgets
UNION ALL SELECT 'transactions',      COUNT(*) FROM transactions
UNION ALL SELECT 'transaction_tags',  COUNT(*) FROM transaction_tags
UNION ALL SELECT 'daily_summaries',   COUNT(*) FROM daily_summaries
UNION ALL SELECT 'monthly_category_totals', COUNT(*) FROM monthly_category_totals
UNION ALL SELECT 'financial_snapshots', COUNT(*) FROM financial_snapshots
UNION ALL SELECT 'anomalies',         COUNT(*) FROM anomalies;
GO

-- Quick income vs expense summary per user per month
SELECT
    u.username,
    fs.year,
    fs.month,
    FORMAT(fs.total_income,   'N0') AS income_vnd,
    FORMAT(fs.total_expenses, 'N0') AS expenses_vnd,
    FORMAT(fs.net_savings,    'N0') AS savings_vnd,
    FORMAT(fs.savings_rate_pct,'N2') + '%' AS savings_rate
FROM financial_snapshots fs
JOIN dbo.users u ON u.user_id = fs.user_id
ORDER BY u.username, fs.year, fs.month;
GO
