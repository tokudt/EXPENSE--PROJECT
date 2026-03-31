USE DATA_expense;
GO
USE DATA_expense;
GO

INSERT INTO dbo.users (user_id, username,email)
VALUES ('1', 'Dat Pham','dat@example.com');

INSERT INTO dbo.accounts (user_id, account_id,name,account_type,institution,balance,currency)
VALUES
(1, 1,'Main Bank','CHECKING','Vietcombank',15000000,'VND'),
(1, 2,'Cash','CASH',NULL,2000000,'VND'),
(1, 3,'Momo','CASH','Momo',1000000,'VND');

INSERT INTO dbo.categories (user_id,category_id,name,expense_type,is_system)
VALUES
(1,1,'Housing','fixed',1),
(1,2,'Food & Dining','variable',1),
(1,3,'Transport','semi_variable',1),
(1,4,'Health','variable',1),
(1,5,'Entertainment','variable',1),
(1,6,'Shopping','variable',1);

INSERT INTO dbo.transactions
(user_id,account_id,category_id,transaction_id,amount,transaction_type,description,transaction_date,currency)
VALUES
(1,1,1,01,25000000,'INCOME','Salary',GETDATE(),'VND'),
(1,1,2,01,25000000,'INCOME','Salary',GETDATE(),'VND'),
(1,1,3,01,25000000,'INCOME','Salary',GETDATE(),'VND'),
(1,1,2,02,500000,'EXPENSE','Groceries',GETDATE(),'VND'),
(1,1,2,03,200000,'EXPENSE','Grab ride',GETDATE(),'VND'),
(1,1,3,04,150000,'EXPENSE','Netflix',GETDATE(),'VND'),
(1,1,2,05,100000,'EXPENSE','Amazon',GETDATE(),'VND'),
(1,1,4,06,300000,'EXPENSE','Doctor visit',GETDATE(),'VND');


INSERT INTO dbo.budgets
(user_id,name,period_type,period_start,period_end,budget_amount)
VALUES
(1,'Food Budget','MONTHLY','2026-02-01','2026-02-28',3000000),
(1,'Transport Budget','MONTHLY','2026-02-01','2026-02-28',1000000);