using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace FinanceApi.Models.Entities;

// ─────────────────────────────────────────────
// USER
// ─────────────────────────────────────────────
[Table("users")]
public class User
{
    [Column("user_id")] public int UserId { get; set; }
    [Column("username")] public string Username { get; set; } = null!;
    [Column("email")] public string Email { get; set; } = null!;
    [Column("password_hash")] public string PasswordHash { get; set; } = null!;
    [Column("currency")] public string Currency { get; set; } = "USD";
    [Column("monthly_income")] public decimal? MonthlyIncome { get; set; }
    [Column("created_at")] public DateTime CreatedAt { get; set; }
    [Column("updated_at")] public DateTime UpdatedAt { get; set; }

    public ICollection<Account> Accounts { get; set; } = new List<Account>();
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
    public ICollection<Budget> Budgets { get; set; } = new List<Budget>();
    public ICollection<Tag> Tags { get; set; } = new List<Tag>();
    public ICollection<Category> Categories { get; set; } = new List<Category>();
}

// ─────────────────────────────────────────────
// CATEGORY
// ─────────────────────────────────────────────
[Table("categories")]
public class Category
{
    [Column("category_id")] public int CategoryId { get; set; }
    [Column("user_id")] public int? UserId { get; set; }
    [Column("parent_id")] public int? ParentId { get; set; }
    [Column("name")] public string Name { get; set; } = null!;
    [Column("icon")] public string? Icon { get; set; }
    [Column("color")] public string? Color { get; set; }
    [Column("expense_type")] public string ExpenseType { get; set; } = "VARIABLE";
    [Column("is_system")] public bool IsSystem { get; set; }
    [Column("created_at")] public DateTime CreatedAt { get; set; }

    public User? User { get; set; }
    public Category? Parent { get; set; }
    public ICollection<Category> Children { get; set; } = new List<Category>();
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}

// ─────────────────────────────────────────────
// ACCOUNT
// ─────────────────────────────────────────────
[Table("accounts")]
public class Account
{
    [Column("account_id")] public int AccountId { get; set; }
    [Column("user_id")] public int UserId { get; set; }
    [Column("name")] public string Name { get; set; } = null!;
    [Column("account_type")] public string AccountType { get; set; } = null!;
    [Column("balance")] public decimal Balance { get; set; }
    [Column("credit_limit")] public decimal? CreditLimit { get; set; }
    [Column("currency")] public string Currency { get; set; } = "USD";
    [Column("institution")] public string? Institution { get; set; }
    [Column("is_active")] public bool IsActive { get; set; } = true;
    [Column("created_at")] public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}

// ─────────────────────────────────────────────
// TAG
// ─────────────────────────────────────────────
[Table("tags")]
public class Tag
{
    [Column("tag_id")] public int TagId { get; set; }
    [Column("user_id")] public int UserId { get; set; }
    [Column("name")] public string Name { get; set; } = null!;

    public User User { get; set; } = null!;
    public ICollection<TransactionTag> TransactionTags { get; set; } = new List<TransactionTag>();
}

// ─────────────────────────────────────────────
// TRANSACTION
// ─────────────────────────────────────────────
[Table("transactions")]
public class Transaction
{
    [Column("transaction_id")] public int TransactionId { get; set; }
    [Column("user_id")] public int UserId { get; set; }
    [Column("account_id")] public int AccountId { get; set; }
    [Column("category_id")] public int? CategoryId { get; set; }
    [Column("amount")] public decimal Amount { get; set; }
    [Column("currency")] public string Currency { get; set; } = "USD";
    [Column("amount_base_currency")] public decimal? AmountBaseCurrency { get; set; }
    [Column("exchange_rate")] public decimal ExchangeRate { get; set; } = 1m;
    [Column("transaction_type")] public string TransactionType { get; set; } = null!;
    [Column("is_recurring")] public bool IsRecurring { get; set; }
    [Column("recurrence_id")] public int? RecurrenceId { get; set; }
    [Column("merchant")] public string? Merchant { get; set; }
    [Column("description")] public string? Description { get; set; }
    [Column("notes")] public string? Notes { get; set; }
    [Column("transaction_date")] public DateOnly TransactionDate { get; set; }
    [Column("posted_date")] public DateOnly? PostedDate { get; set; }
    [Column("latitude")] public decimal? Latitude { get; set; }
    [Column("longitude")] public decimal? Longitude { get; set; }
    [Column("city")] public string? City { get; set; }
    [Column("country")] public string? Country { get; set; }
    [Column("is_verified")] public bool IsVerified { get; set; }
    [Column("is_excluded")] public bool IsExcluded { get; set; }
    [Column("created_at")] public DateTime CreatedAt { get; set; }
    [Column("updated_at")] public DateTime UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public Account Account { get; set; } = null!;
    public Category? Category { get; set; }
    public RecurringRule? RecurringRule { get; set; }
    public ICollection<TransactionTag> TransactionTags { get; set; } = new List<TransactionTag>();
}

// ─────────────────────────────────────────────
// TRANSACTION TAG (join)
// ─────────────────────────────────────────────
[Table("transaction_tags")]
public class TransactionTag
{
    [Column("transaction_id")] public int TransactionId { get; set; }
    [Column("tag_id")] public int TagId { get; set; }

    public Transaction Transaction { get; set; } = null!;
    public Tag Tag { get; set; } = null!;
}

// ─────────────────────────────────────────────
// RECURRING RULE
// ─────────────────────────────────────────────
[Table("recurring_rules")]
public class RecurringRule
{
    [Column("recurrence_id")] public int RecurrenceId { get; set; }
    [Column("user_id")] public int UserId { get; set; }
    [Column("account_id")] public int AccountId { get; set; }
    [Column("category_id")] public int? CategoryId { get; set; }
    [Column("transaction_type")] public string TransactionType { get; set; } = null!;
    [Column("amount")] public decimal Amount { get; set; }
    [Column("description")] public string? Description { get; set; }
    [Column("frequency")] public string Frequency { get; set; } = null!;
    [Column("start_date")] public DateOnly StartDate { get; set; }
    [Column("end_date")] public DateOnly? EndDate { get; set; }
    [Column("last_generated_date")] public DateOnly? LastGeneratedDate { get; set; }
    [Column("is_active")] public bool IsActive { get; set; } = true;
    [Column("created_at")] public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}

// ─────────────────────────────────────────────
// BUDGET
// ─────────────────────────────────────────────
[Table("budgets")]
public class Budget
{
    [Column("budget_id")] public int BudgetId { get; set; }
    [Column("user_id")] public int UserId { get; set; }
    [Column("category_id")] public int? CategoryId { get; set; }
    [Column("name")] public string Name { get; set; } = null!;
    [Column("period_type")] public string PeriodType { get; set; } = "MONTHLY";
    [Column("period_start")] public DateOnly PeriodStart { get; set; }
    [Column("period_end")] public DateOnly PeriodEnd { get; set; }
    [Column("budgeted_amount")] public decimal BudgetedAmount { get; set; }
    [Column("rollover")] public bool Rollover { get; set; }
    [Column("alert_threshold")] public decimal AlertThreshold { get; set; } = 80m;
    [Column("is_active")] public bool IsActive { get; set; } = true;
    [Column("created_at")] public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
    public Category? Category { get; set; }
}

// ─────────────────────────────────────────────
// DAILY SUMMARY
// ─────────────────────────────────────────────
[Table("daily_summaries")]
public class DailySummary
{
    [Column("summary_id")] public int SummaryId { get; set; }
    [Column("user_id")] public int UserId { get; set; }
    [Column("summary_date")] public DateOnly SummaryDate { get; set; }
    [Column("total_expenses")] public decimal TotalExpenses { get; set; }
    [Column("total_income")] public decimal TotalIncome { get; set; }
    [Column("net_flow")] public decimal NetFlow { get; set; }
    [Column("transaction_count")] public int TransactionCount { get; set; }

    public User User { get; set; } = null!;
}

// ─────────────────────────────────────────────
// MONTHLY CATEGORY TOTALS
// ─────────────────────────────────────────────
[Table("monthly_category_totals")]
public class MonthlyCategoryTotal
{
    [Column("id")] public int Id { get; set; }
    [Column("user_id")] public int UserId { get; set; }
    [Column("category_id")] public int CategoryId { get; set; }
    [Column("year")] public short Year { get; set; }
    [Column("month")] public short Month { get; set; }
    [Column("total_amount")] public decimal TotalAmount { get; set; }
    [Column("transaction_count")] public int TransactionCount { get; set; }
    [Column("avg_transaction")] public decimal? AvgTransaction { get; set; }

    public User User { get; set; } = null!;
    public Category Category { get; set; } = null!;
}

// ─────────────────────────────────────────────
// FINANCIAL SNAPSHOT
// ─────────────────────────────────────────────
[Table("financial_snapshots")]
public class FinancialSnapshot
{
    [Column("snapshot_id")] public int SnapshotId { get; set; }
    [Column("user_id")] public int UserId { get; set; }
    [Column("year")] public short Year { get; set; }
    [Column("month")] public short Month { get; set; }
    [Column("total_expenses")] public decimal? TotalExpenses { get; set; }
    [Column("total_income")] public decimal? TotalIncome { get; set; }
    [Column("net_savings")] public decimal? NetSavings { get; set; }
    [Column("savings_rate_pct")] public decimal? SavingsRatePct { get; set; }
    [Column("fixed_expense_total")] public decimal? FixedExpenseTotal { get; set; }
    [Column("variable_expense_total")] public decimal? VariableExpenseTotal { get; set; }
    [Column("budget_adherence_pct")] public decimal? BudgetAdherencePct { get; set; }
    [Column("overspent_categories")] public string? OverspentCategories { get; set; }
    [Column("anomaly_flags")] public string? AnomalyFlags { get; set; }
    [Column("spending_consistency_score")] public decimal? SpendingConsistencyScore { get; set; }
    [Column("burn_rate")] public decimal? BurnRate { get; set; }
    [Column("predicted_next_month")] public decimal? PredictedNextMonth { get; set; }
    [Column("months_of_runway")] public decimal? MonthsOfRunway { get; set; }
    [Column("computed_at")] public DateTime ComputedAt { get; set; }

    public User User { get; set; } = null!;
}

// ─────────────────────────────────────────────
// ANOMALY
// ─────────────────────────────────────────────
[Table("anomalies")]
public class Anomaly
{
    [Column("anomaly_id")] public int AnomalyId { get; set; }
    [Column("user_id")] public int UserId { get; set; }
    [Column("transaction_id")] public int? TransactionId { get; set; }
    [Column("category_id")] public int? CategoryId { get; set; }
    [Column("anomaly_type")] public string AnomalyType { get; set; } = null!;
    [Column("severity")] public string Severity { get; set; } = "MEDIUM";
    [Column("description")] public string? Description { get; set; }
    [Column("detected_at")] public DateTime DetectedAt { get; set; }
    [Column("acknowledged_at")] public DateTime? AcknowledgedAt { get; set; }
    [Column("is_false_positive")] public bool IsFalsePositive { get; set; }

    public User User { get; set; } = null!;
    public Transaction? Transaction { get; set; }
    public Category? Category { get; set; }
}

// ─────────────────────────────────────────────
// EXPENSE PREDICTION
// ─────────────────────────────────────────────
[Table("expense_predictions")]
public class ExpensePrediction
{
    [Column("prediction_id")] public int PredictionId { get; set; }
    [Column("user_id")] public int UserId { get; set; }
    [Column("category_id")] public int? CategoryId { get; set; }
    [Column("target_year")] public short TargetYear { get; set; }
    [Column("target_month")] public short TargetMonth { get; set; }
    [Column("predicted_amount")] public decimal PredictedAmount { get; set; }
    [Column("confidence_lower")] public decimal? ConfidenceLower { get; set; }
    [Column("confidence_upper")] public decimal? ConfidenceUpper { get; set; }
    [Column("model_name")] public string? ModelName { get; set; }
    [Column("created_at")] public DateTime CreatedAt { get; set; }

    public User User { get; set; } = null!;
    public Category? Category { get; set; }
}
