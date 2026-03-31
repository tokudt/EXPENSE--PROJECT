DROP TABLE dbo.users;
GO

CREATE TABLE dbo.users (
	user_id		INT IDENTITY(1,1) PRIMARY KEY,
	username	NVARCHAR(100) NOT NULL UNIQUE,
	email		NVARCHAR(255)NOT NULL UNIQUE,
	currency	CHAR(5) NOT NULL DEFAULT 'DONG',
	created_at 	DATETIME2 DEFAULT SYSDATETIME(),
	updated_at 	DATETIME2 DEFAULT SYSDATETIME(),
	row_version ROWVERSION
);

DROP TABLE dbo.accounts;
GO

CREATE TABLE dbo.accounts (
	account_id	INT PRIMARY KEY,
	user_id		INT NOT NULL REFERENCES dbo.users(user_id),
	name		NVARCHAR(100) NOT NULL,
	account_type NVARCHAR(30) NOT NULL
					CHECK (account_type IN ('CHECKING', 'SAVING', 'CREDIT_CARD', 'CASH', 'INVESTMENT', 'LOAN')),
	balance		DECIMAL(14,2) NOT NULL DEFAULT 0,
	credit_limit DECIMAL(14,2),
	currency	CHAR(5) NOT NULL DEFAULT 'DONG',
	institution	NVARCHAR(100),
	is_active	BIT NOT NULL DEFAULT 1,
	created_at	DATETIME NOT NULL DEFAULT GETDATE()
);

DROP TABLE dbo.categories;
GO

CREATE TABLE dbo.categories (
	category_id INT IDENTITY(1,1) PRIMARY KEY,
	user_id		INT REFERENCES dbo.users(user_id) ON DELETE CASCADE,
	parent_id	INT NULL REFERENCES dbo.categories(category_id),
	name 		NVARCHAR(100) NOT NULL,
	icon		NVARCHAR(255) NULL,
	color		NVARCHAR(7) NULL, -- HEX color code
	expense_type NVARCHAR(20) NOT NULL DEFAULT 'variable'
					CHECK (expense_type IN ('fixed', 'variable', 'semi_variable')),
	is_system   BIT NOT NULL DEFAULT 0,   -- built-in vs user-defined use BIT for boolean)

	created_at DATETIME2 DEFAULT SYSDATETIME(),
	updated_at DATETIME2 DEFAULT SYSDATETIME()
);

