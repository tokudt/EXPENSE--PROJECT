namespace FinanceApi.Models.DTOs;

// ────────────────────── AUTH ──────────────────────
public record RegisterRequest(string Username, string Email, string Password, string Currency = "USD", decimal? MonthlyIncome = null);
public record LoginRequest(string Email, string Password);
public record AuthResponse(string Token, string Username, string Email, DateTime ExpiresAt);

// ────────────────────── USER ──────────────────────
public record UserDto(int UserId, string Username, string Email, string Currency, decimal? MonthlyIncome, DateTime CreatedAt);
public record UpdateUserRequest(string? Currency, decimal? MonthlyIncome);

// ────────────────────── CATEGORY ──────────────────────
public record CategoryDto(int CategoryId, int? UserId, int? ParentId, string Name, string? Icon, string? Color, string ExpenseType, bool IsSystem, List<CategoryDto>? Children);
public record CreateCategoryRequest(int? ParentId, string Name, string? Icon, string? Color, string ExpenseType = "VARIABLE");
public record UpdateCategoryRequest(string? Name, string? Icon, string? Color, string? ExpenseType);

// ────────────────────── ACCOUNT ──────────────────────
public record AccountDto(int AccountId, string Name, string AccountType, decimal Balance, decimal? CreditLimit, string Currency, string? Institution, bool IsActive, DateTime CreatedAt);
public record CreateAccountRequest(string Name, string AccountType, decimal Balance, decimal? CreditLimit, string Currency = "USD", string? Institution = null);
public record UpdateAccountRequest(string? Name, decimal? Balance, string? Institution, bool? IsActive);

// ────────────────────── TAG ──────────────────────
public record TagDto(int TagId, string Name);
public record CreateTagRequest(string Name);

// ────────────────────── TRANSACTION ──────────────────────
public record TransactionDto(
    int TransactionId, int AccountId, int? CategoryId,
    string? CategoryName, string? AccountName,
    decimal Amount, string Currency, string TransactionType,
    bool IsRecurring, string? Merchant, string? Description,
    string? Notes, DateOnly TransactionDate, DateOnly? PostedDate,
    string? City, string? Country,
    bool IsVerified, bool IsExcluded,
    List<TagDto> Tags, DateTime CreatedAt);

public record CreateTransactionRequest(
    int AccountId, int? CategoryId,
    decimal Amount, string Currency = "USD",
    string TransactionType = "EXPENSE",
    bool IsRecurring = false, int? RecurrenceId = null,
    string? Merchant = null, string? Description = null, string? Notes = null,
    DateOnly? TransactionDate = null, DateOnly? PostedDate = null,
    decimal? Latitude = null, decimal? Longitude = null,
    string? City = null, string? Country = null,
    List<int>? TagIds = null);

public record UpdateTransactionRequest(
    int? CategoryId, decimal? Amount, string? Merchant,
    string? Description, string? Notes,
    DateOnly? TransactionDate, bool? IsVerified,
    bool? IsExcluded, List<int>? TagIds);

public record TransactionFilterRequest(
    DateOnly? From = null, DateOnly? To = null,
    int? CategoryId = null, int? AccountId = null,
    string? TransactionType = null, string? Merchant = null,
    bool? IsExcluded = null, int Page = 1, int PageSize = 50);

public record PagedResult<T>(IEnumerable<T> Items, int Total, int Page, int PageSize, int TotalPages);

// ────────────────────── BUDGET ──────────────────────
public record BudgetDto(int BudgetId, int? CategoryId, string? CategoryName, string Name,
    string PeriodType, DateOnly PeriodStart, DateOnly PeriodEnd,
    decimal BudgetedAmount, decimal SpentAmount, decimal Remaining,
    decimal PctUsed, bool IsOverspent, bool IsActive);

public record CreateBudgetRequest(int? CategoryId, string Name, string PeriodType,
    DateOnly PeriodStart, DateOnly PeriodEnd, decimal BudgetedAmount,
    bool Rollover = false, decimal AlertThreshold = 80m);

public record UpdateBudgetRequest(string? Name, decimal? BudgetedAmount, decimal? AlertThreshold, bool? IsActive);

// ────────────────────── RECURRING ──────────────────────
public record RecurringRuleDto(int RecurrenceId, int AccountId, int? CategoryId,
    string TransactionType, decimal Amount, string? Description,
    string Frequency, DateOnly StartDate, DateOnly? EndDate, bool IsActive);

public record CreateRecurringRuleRequest(int AccountId, int? CategoryId,
    string TransactionType, decimal Amount, string? Description,
    string Frequency, DateOnly StartDate, DateOnly? EndDate);

// ────────────────────── ANALYTICS ──────────────────────
public record CategorySpendDto(string Category, string ExpenseType, decimal TotalSpent, int TxnCount, decimal AvgPerTxn);
public record CategoryGrowthDto(string Category, int Year, int Month, decimal CurrentAmount, decimal? PrevAmount, decimal? GrowthPct);
public record FixedVariableSplitDto(DateTime Month, decimal FixedTotal, decimal VariableTotal, decimal SemiVariableTotal, decimal GrandTotal);
public record DailyTrendDto(DateOnly Date, decimal TotalExpenses, decimal TotalIncome, decimal NetFlow, decimal? Rolling7dAvg, decimal? Rolling30dAvg);
public record BudgetAdherenceDto(int BudgetId, string BudgetName, string? Category, decimal BudgetedAmount, decimal SpentAmount, decimal Remaining, decimal PctUsed, bool IsOverspent);
public record SavingsRateDto(int Year, int Month, decimal? TotalIncome, decimal? TotalExpenses, decimal? NetSavings, decimal? SavingsRatePct, decimal? BurnRate, decimal? MonthsOfRunway, decimal? PredictedNextMonth);
public record FinancialSnapshotDto(int Year, int Month, decimal? TotalExpenses, decimal? TotalIncome, decimal? NetSavings, decimal? SavingsRatePct, decimal? FixedExpenseTotal, decimal? VariableExpenseTotal, decimal? BudgetAdherencePct, decimal? SpendingConsistencyScore, decimal? BurnRate, decimal? PredictedNextMonth, decimal? MonthsOfRunway);
public record ConsistencyScoreDto(int Year, int Month, decimal? Score);

// ────────────────────── ANOMALIES ──────────────────────
public record AnomalyDto(int AnomalyId, int? TransactionId, int? CategoryId, string? CategoryName, string AnomalyType, string Severity, string? Description, DateTime DetectedAt, bool IsFalsePositive);
public record AcknowledgeAnomalyRequest(bool IsFalsePositive = false);

// ────────────────────── PREDICTIONS ──────────────────────
public record PredictionDto(int? CategoryId, string? CategoryName, int TargetYear, int TargetMonth, decimal PredictedAmount, decimal? ConfidenceLower, decimal? ConfidenceUpper, string? ModelName);
