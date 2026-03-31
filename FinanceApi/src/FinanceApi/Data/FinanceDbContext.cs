using FinanceApi.Models.Entities;
using Microsoft.EntityFrameworkCore;

namespace FinanceApi.Data;

public class FinanceDbContext : DbContext
{
    public FinanceDbContext(DbContextOptions<FinanceDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Account> Accounts => Set<Account>();
    public DbSet<Tag> Tags => Set<Tag>();
    public DbSet<Transaction> Transactions => Set<Transaction>();
    public DbSet<TransactionTag> TransactionTags => Set<TransactionTag>();
    public DbSet<RecurringRule> RecurringRules => Set<RecurringRule>();
    public DbSet<Budget> Budgets => Set<Budget>();
    public DbSet<DailySummary> DailySummaries => Set<DailySummary>();
    public DbSet<MonthlyCategoryTotal> MonthlyCategoryTotals => Set<MonthlyCategoryTotal>();
    public DbSet<FinancialSnapshot> FinancialSnapshots => Set<FinancialSnapshot>();
    public DbSet<Anomaly> Anomalies => Set<Anomaly>();
    public DbSet<ExpensePrediction> ExpensePredictions => Set<ExpensePrediction>();

    protected override void OnModelCreating(ModelBuilder mb)
    {
        // ── User ──
        mb.Entity<User>(e =>
        {
            e.HasKey(x => x.UserId);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("NOW()");
            e.Property(x => x.UpdatedAt).HasDefaultValueSql("NOW()");
        });

        // ── Category (self-referencing) ──
        mb.Entity<Category>(e =>
        {
            e.HasKey(x => x.CategoryId);
            e.HasOne(x => x.Parent).WithMany(x => x.Children).HasForeignKey(x => x.ParentId);
            e.HasOne(x => x.User).WithMany(x => x.Categories).HasForeignKey(x => x.UserId);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("NOW()");
        });

        // ── Account ──
        mb.Entity<Account>(e =>
        {
            e.HasKey(x => x.AccountId);
            e.HasOne(x => x.User).WithMany(x => x.Accounts).HasForeignKey(x => x.UserId);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("NOW()");
        });

        // ── Tag ──
        mb.Entity<Tag>(e =>
        {
            e.HasKey(x => x.TagId);
            e.HasOne(x => x.User).WithMany(x => x.Tags).HasForeignKey(x => x.UserId);
            e.HasIndex(x => new { x.UserId, x.Name }).IsUnique();
        });

        // ── Transaction ──
        mb.Entity<Transaction>(e =>
        {
            e.HasKey(x => x.TransactionId);
            e.HasOne(x => x.User).WithMany(x => x.Transactions).HasForeignKey(x => x.UserId);
            e.HasOne(x => x.Account).WithMany(x => x.Transactions).HasForeignKey(x => x.AccountId);
            e.HasOne(x => x.Category).WithMany(x => x.Transactions).HasForeignKey(x => x.CategoryId);
            e.HasOne(x => x.RecurringRule).WithMany(x => x.Transactions).HasForeignKey(x => x.RecurrenceId);
            e.Property(x => x.ExchangeRate).HasDefaultValue(1m);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("NOW()");
            e.Property(x => x.UpdatedAt).HasDefaultValueSql("NOW()");
        });

        // ── TransactionTag (composite PK) ──
        mb.Entity<TransactionTag>(e =>
        {
            e.HasKey(x => new { x.TransactionId, x.TagId });
            e.HasOne(x => x.Transaction).WithMany(x => x.TransactionTags).HasForeignKey(x => x.TransactionId);
            e.HasOne(x => x.Tag).WithMany(x => x.TransactionTags).HasForeignKey(x => x.TagId);
        });

        // ── RecurringRule ──
        mb.Entity<RecurringRule>(e =>
        {
            e.HasKey(x => x.RecurrenceId);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("NOW()");
        });

        // ── Budget ──
        mb.Entity<Budget>(e =>
        {
            e.HasKey(x => x.BudgetId);
            e.HasOne(x => x.User).WithMany(x => x.Budgets).HasForeignKey(x => x.UserId);
            e.Property(x => x.CreatedAt).HasDefaultValueSql("NOW()");
        });

        // ── DailySummary ──
        mb.Entity<DailySummary>(e =>
        {
            e.HasKey(x => x.SummaryId);
            e.HasIndex(x => new { x.UserId, x.SummaryDate }).IsUnique();
            // net_flow is a generated column — never write to it
            e.Property(x => x.NetFlow).ValueGeneratedOnAddOrUpdate();
        });

        // ── MonthlyCategoryTotal ──
        mb.Entity<MonthlyCategoryTotal>(e =>
        {
            e.HasKey(x => x.Id);
            e.HasIndex(x => new { x.UserId, x.CategoryId, x.Year, x.Month }).IsUnique();
        });

        // ── FinancialSnapshot ──
        mb.Entity<FinancialSnapshot>(e =>
        {
            e.HasKey(x => x.SnapshotId);
            e.HasIndex(x => new { x.UserId, x.Year, x.Month }).IsUnique();
            e.Property(x => x.OverspentCategories).HasColumnType("jsonb");
            e.Property(x => x.AnomalyFlags).HasColumnType("jsonb");
        });

        // ── Anomaly ──
        mb.Entity<Anomaly>(e =>
        {
            e.HasKey(x => x.AnomalyId);
            e.Property(x => x.DetectedAt).HasDefaultValueSql("NOW()");
        });

        // ── ExpensePrediction ──
        mb.Entity<ExpensePrediction>(e =>
        {
            e.HasKey(x => x.PredictionId);
            e.HasIndex(x => new { x.UserId, x.CategoryId, x.TargetYear, x.TargetMonth }).IsUnique();
            e.Property(x => x.CreatedAt).HasDefaultValueSql("NOW()");
        });
    }
}
