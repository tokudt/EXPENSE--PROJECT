# 💰 Personal Finance API — .NET 8

A production-ready REST API built with **ASP.NET Core 8**, **Entity Framework Core**, and **PostgreSQL**.  
Fully aligned with the `personal_finance_db.sql` schema.

---

## 🏗️ Project Structure

```
FinanceApi/
├── src/FinanceApi/
│   ├── Controllers/        # All API endpoints
│   ├── Data/               # EF Core DbContext
│   ├── Extensions/         # DI & Swagger setup
│   ├── Middleware/          # Global exception handler
│   ├── Models/
│   │   ├── Entities/       # EF Core entity classes
│   │   └── DTOs/           # Request & response records
│   ├── Services/           # Business logic
│   │   └── Interfaces/     # Service contracts
│   └── Validators/         # FluentValidation rules
├── Dockerfile
├── docker-compose.yml
└── README.md
```

---

## 🚀 Quick Start

### Option A — Docker (recommended)

```bash
# Copy the SQL file next to docker-compose.yml first
cp personal_finance_db.sql ./personal_finance_db.sql

docker compose up --build
```

API available at: **http://localhost:8080**  
Swagger UI: **http://localhost:8080/index.html**

### Option B — Local

**Prerequisites:** .NET 8 SDK, PostgreSQL 13+

```bash
# 1. Restore database
psql -U postgres -c "CREATE DATABASE personal_finance;"
psql -U postgres -d personal_finance -f personal_finance_db.sql

# 2. Update connection string in appsettings.json

# 3. Run
cd src/FinanceApi
dotnet run
```

---

## 🔐 Authentication

All endpoints except `/api/auth/*` require a **Bearer JWT** token.

```bash
# 1. Register
POST /api/auth/register
{
  "username": "alice",
  "email": "alice@example.com",
  "password": "SecurePass123",
  "currency": "USD",
  "monthlyIncome": 5000
}

# 2. Login → get token
POST /api/auth/login
{ "email": "alice@example.com", "password": "SecurePass123" }

# 3. Use token in all requests
Authorization: Bearer <token>
```

---

## 📡 API Endpoints

### Auth
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/register` | Create account |
| POST | `/api/auth/login` | Login, get JWT |

### Users
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/users/me` | Get current user |
| PATCH | `/api/users/me` | Update currency / income |

### Categories
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/categories` | List all (system + custom), hierarchical |
| GET | `/api/categories/{id}` | Get one |
| POST | `/api/categories` | Create custom category |
| PATCH | `/api/categories/{id}` | Update |
| DELETE | `/api/categories/{id}` | Delete (user-defined only) |

### Accounts
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/accounts` | List active accounts |
| GET | `/api/accounts/{id}` | Get one |
| POST | `/api/accounts` | Create account |
| PATCH | `/api/accounts/{id}` | Update |
| DELETE | `/api/accounts/{id}` | Soft-delete (deactivate) |

### Tags
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/tags` | List tags |
| POST | `/api/tags` | Create tag |
| DELETE | `/api/tags/{id}` | Delete tag |

### Transactions
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/transactions` | Paginated + filtered list |
| GET | `/api/transactions/{id}` | Get one |
| POST | `/api/transactions` | Create |
| PATCH | `/api/transactions/{id}` | Update |
| DELETE | `/api/transactions/{id}` | Delete |

**Filter query params:**
```
?from=2025-01-01&to=2025-03-31
&categoryId=2
&accountId=1
&transactionType=EXPENSE
&merchant=Netflix
&isExcluded=false
&page=1&pageSize=50
```

### Budgets
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/budgets` | List active budgets with live spend |
| GET | `/api/budgets/{id}` | Get one |
| POST | `/api/budgets` | Create |
| PATCH | `/api/budgets/{id}` | Update |
| DELETE | `/api/budgets/{id}` | Deactivate |

### Recurring Rules
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/recurring` | List rules |
| GET | `/api/recurring/{id}` | Get one |
| POST | `/api/recurring` | Create rule |
| DELETE | `/api/recurring/{id}` | Deactivate rule |

---

## 📊 Analytics Endpoints

All analytics endpoints are scoped to the authenticated user.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/analytics/spend-by-category` | Where is money going? |
| GET | `/api/analytics/category-growth` | Fastest growing categories (MoM %) |
| GET | `/api/analytics/fixed-variable-split` | Fixed vs variable split per month |
| GET | `/api/analytics/daily-trend` | Daily trend + 7d/30d rolling averages |
| GET | `/api/analytics/budget-adherence` | Budget adherence + overspending |
| GET | `/api/analytics/savings-rate` | Savings rate, burn rate, runway |
| GET | `/api/analytics/consistency-score` | Spending consistency score 0–100 |
| GET | `/api/analytics/snapshot` | Full monthly financial snapshot |
| GET | `/api/analytics/anomalies` | Detected anomalies |
| PATCH | `/api/analytics/anomalies/{id}/acknowledge` | Acknowledge / mark false positive |
| GET | `/api/analytics/predictions` | Predicted next month expenses |

**Example calls:**
```bash
# Current month spend breakdown
GET /api/analytics/spend-by-category

# Last 3 months with custom date range
GET /api/analytics/spend-by-category?from=2025-01-01&to=2025-03-31

# Category growth last 6 months
GET /api/analytics/category-growth?months=6

# Daily trend last 30 days
GET /api/analytics/daily-trend?days=30

# Consistency score for Feb 2025
GET /api/analytics/consistency-score?year=2025&month=2

# Snapshot for last month
GET /api/analytics/snapshot?year=2025&month=2

# Predictions for next month
GET /api/analytics/predictions
```

---

## 🛠️ Tech Stack

| Concern | Library |
|---------|---------|
| Framework | ASP.NET Core 8 |
| ORM | Entity Framework Core 8 |
| Database | PostgreSQL (Npgsql) |
| Auth | JWT Bearer (Microsoft.AspNetCore.Authentication.JwtBearer) |
| Validation | FluentValidation |
| Docs | Swashbuckle (Swagger / OpenAPI) |
| Logging | Serilog |
| Password | BCrypt.Net |

---

## ⚙️ Configuration

Edit `appsettings.json` or set environment variables:

| Key | Description |
|-----|-------------|
| `ConnectionStrings__DefaultConnection` | PostgreSQL connection string |
| `Jwt__Key` | 256-bit secret (change in production!) |
| `Jwt__ExpiryHours` | Token lifetime (default 24) |

---

## 📦 NuGet Packages

```bash
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package Swashbuckle.AspNetCore
dotnet add package FluentValidation.AspNetCore
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.Console
dotnet add package BCrypt.Net-Next
```

---

## 🗺️ Roadmap

- [ ] EF Core migrations (`dotnet ef migrations add InitialCreate`)  
- [ ] Background service to auto-generate recurring transactions  
- [ ] Anomaly detection background job  
- [ ] Monthly snapshot computation job  
- [ ] ML.NET integration for expense predictions  
- [ ] Rate limiting  
- [ ] Multi-currency FX conversion  
