using FinanceApi.Data;
using FinanceApi.Models.DTOs;
using FinanceApi.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FinanceApi.Services;

public class AnalyticsService : IAnalyticsService
{
    private readonly FinanceDbContext _db;
    public AnalyticsService(FinanceDbContext db) => _db = db;

    // ── WHERE IS MONEY GOING? ──────────────────────────────
    public async Task<IEnumerable<CategorySpendDto>> GetSpendByCategoryAsync(int userId, DateOnly? from, DateOnly? to)
    {
        var fromDate = from ?? DateOnly.FromDateTime(new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1));
        var toDate   = to   ?? DateOnly.FromDateTime(DateTime.UtcNow);

        var result = await _db.Transactions
            .Where(t => t.UserId == userId
                && t.TransactionType == "EXPENSE"
                && !t.IsExcluded
                && t.TransactionDate >= fromDate
                && t.TransactionDate <= toDate
                && t.CategoryId != null)
            .GroupBy(t => new { t.CategoryId, t.Category!.Name, t.Category.ExpenseType })
            .Select(g => new CategorySpendDto(
                g.Key.Name,
                g.Key.ExpenseType,
                g.Sum(t => t.Amount),
                g.Count(),
                Math.Round(g.Average(t => t.Amount), 2)))
            .OrderByDescending(x => x.TotalSpent)
            .ToListAsync();

        return result;
    }

    // ── WHICH CATEGORIES GROW FASTEST? ────────────────────
    public async Task<IEnumerable<CategoryGrowthDto>> GetCategoryGrowthAsync(int userId, int months)
    {
        var cutoff = DateTime.UtcNow.AddMonths(-months);
        var cutoffYear  = (short)cutoff.Year;
        var cutoffMonth = (short)cutoff.Month;

        var totals = await _db.MonthlyCategoryTotals
            .Include(m => m.Category)
            .Where(m => m.UserId == userId
                && (m.Year > cutoffYear || (m.Year == cutoffYear && m.Month >= cutoffMonth)))
            .OrderBy(m => m.CategoryId).ThenBy(m => m.Year).ThenBy(m => m.Month)
            .ToListAsync();

        var result = new List<CategoryGrowthDto>();
        foreach (var cur in totals)
        {
            var prev = totals.FirstOrDefault(p =>
                p.CategoryId == cur.CategoryId &&
                (p.Year * 12 + p.Month) == (cur.Year * 12 + cur.Month) - 1);

            decimal? growthPct = null;
            if (prev != null && prev.TotalAmount > 0)
                growthPct = Math.Round((cur.TotalAmount - prev.TotalAmount) / prev.TotalAmount * 100, 2);

            result.Add(new CategoryGrowthDto(
                cur.Category.Name, cur.Year, cur.Month,
                cur.TotalAmount, prev?.TotalAmount, growthPct));
        }

        return result.OrderByDescending(r => r.GrowthPct);
    }

    // ── FIXED VS VARIABLE SPLIT ────────────────────────────
    public async Task<IEnumerable<FixedVariableSplitDto>> GetFixedVariableSplitAsync(int userId, int months)
    {
        var fromDate = DateOnly.FromDateTime(DateTime.UtcNow.AddMonths(-months));

        var rows = await _db.Transactions
            .Include(t => t.Category)
            .Where(t => t.UserId == userId
                && t.TransactionType == "EXPENSE"
                && !t.IsExcluded
                && t.TransactionDate >= fromDate
                && t.CategoryId != null)
            .ToListAsync();

        return rows
            .GroupBy(t => new DateTime(t.TransactionDate.Year, t.TransactionDate.Month, 1))
            .OrderByDescending(g => g.Key)
            .Select(g => new FixedVariableSplitDto(
                g.Key,
                g.Where(t => t.Category?.ExpenseType == "FIXED").Sum(t => t.Amount),
                g.Where(t => t.Category?.ExpenseType == "VARIABLE").Sum(t => t.Amount),
                g.Where(t => t.Category?.ExpenseType == "SEMI_VARIABLE").Sum(t => t.Amount),
                g.Sum(t => t.Amount)));
    }

    // ── DAILY TREND ────────────────────────────────────────
    public async Task<IEnumerable<DailyTrendDto>> GetDailyTrendAsync(int userId, int days)
    {
        var fromDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-days));

        var summaries = await _db.DailySummaries
            .Where(s => s.UserId == userId && s.SummaryDate >= fromDate)
            .OrderBy(s => s.SummaryDate)
            .ToListAsync();

        var result = new List<DailyTrendDto>();
        for (int i = 0; i < summaries.Count; i++)
        {
            var s = summaries[i];
            var prev7  = summaries.Skip(Math.Max(0, i - 6)).Take(7).ToList();
            var prev30 = summaries.Skip(Math.Max(0, i - 29)).Take(30).ToList();

            result.Add(new DailyTrendDto(
                s.SummaryDate,
                s.TotalExpenses,
                s.TotalIncome,
                s.NetFlow,
                prev7.Count  > 0 ? Math.Round(prev7.Average(x => x.TotalExpenses), 2)  : null,
                prev30.Count > 0 ? Math.Round(prev30.Average(x => x.TotalExpenses), 2) : null));
        }

        return result;
    }

    // ── BUDGET ADHERENCE ───────────────────────────────────
    public async Task<IEnumerable<BudgetAdherenceDto>> GetBudgetAdherenceAsync(int userId)
    {
        var budgets = await _db.Budgets
            .Include(b => b.Category)
            .Where(b => b.UserId == userId && b.IsActive)
            .ToListAsync();

        var result = new List<BudgetAdherenceDto>();
        foreach (var b in budgets)
        {
            var spent = await _db.Transactions
                .Where(t => t.UserId == userId
                    && (b.CategoryId == null || t.CategoryId == b.CategoryId)
                    && t.TransactionDate >= b.PeriodStart
                    && t.TransactionDate <= b.PeriodEnd
                    && t.TransactionType == "EXPENSE"
                    && !t.IsExcluded)
                .SumAsync(t => (decimal?)t.Amount) ?? 0;

            var remaining = b.BudgetedAmount - spent;
            var pct = b.BudgetedAmount > 0 ? Math.Round(spent / b.BudgetedAmount * 100, 2) : 0;

            result.Add(new BudgetAdherenceDto(b.BudgetId, b.Name, b.Category?.Name,
                b.BudgetedAmount, spent, remaining, pct, spent > b.BudgetedAmount));
        }

        return result.OrderByDescending(r => r.PctUsed);
    }

    // ── SAVINGS RATE ───────────────────────────────────────
    public async Task<IEnumerable<SavingsRateDto>> GetSavingsRateAsync(int userId, int months)
    {
        return await _db.FinancialSnapshots
            .Where(s => s.UserId == userId)
            .OrderByDescending(s => s.Year).ThenByDescending(s => s.Month)
            .Take(months)
            .Select(s => new SavingsRateDto(
                s.Year, s.Month, s.TotalIncome, s.TotalExpenses, s.NetSavings,
                s.SavingsRatePct, s.BurnRate, s.MonthsOfRunway, s.PredictedNextMonth))
            .ToListAsync();
    }

    // ── CONSISTENCY SCORE ──────────────────────────────────
    public async Task<ConsistencyScoreDto> GetConsistencyScoreAsync(int userId, int year, int month)
    {
        var summaries = await _db.DailySummaries
            .Where(s => s.UserId == userId
                && s.SummaryDate.Year == year
                && s.SummaryDate.Month == month)
            .Select(s => s.TotalExpenses)
            .ToListAsync();

        if (!summaries.Any())
            return new ConsistencyScoreDto(year, month, null);

        var mean   = summaries.Average();
        if (mean == 0) return new ConsistencyScoreDto(year, month, 100m);

        var variance = summaries.Average(v => Math.Pow((double)(v - (decimal)mean), 2));
        var stddev   = (decimal)Math.Sqrt(variance);
        var cv       = stddev / (decimal)mean;
        var score    = Math.Max(0, Math.Min(100, Math.Round(100m * (1m - Math.Min(cv, 1m)), 2)));

        return new ConsistencyScoreDto(year, month, score);
    }

    // ── FINANCIAL SNAPSHOT ─────────────────────────────────
    public async Task<FinancialSnapshotDto?> GetSnapshotAsync(int userId, int year, int month)
    {
        var s = await _db.FinancialSnapshots
            .FirstOrDefaultAsync(x => x.UserId == userId && x.Year == year && x.Month == month);

        if (s == null) return null;

        return new FinancialSnapshotDto(s.Year, s.Month, s.TotalExpenses, s.TotalIncome,
            s.NetSavings, s.SavingsRatePct, s.FixedExpenseTotal, s.VariableExpenseTotal,
            s.BudgetAdherencePct, s.SpendingConsistencyScore, s.BurnRate,
            s.PredictedNextMonth, s.MonthsOfRunway);
    }

    // ── ANOMALIES ──────────────────────────────────────────
    public async Task<IEnumerable<AnomalyDto>> GetAnomaliesAsync(int userId, bool includeFalsePositives)
    {
        var q = _db.Anomalies
            .Include(a => a.Category)
            .Where(a => a.UserId == userId);

        if (!includeFalsePositives)
            q = q.Where(a => !a.IsFalsePositive);

        return (await q.OrderByDescending(a => a.DetectedAt).ToListAsync())
            .Select(a => new AnomalyDto(
                a.AnomalyId, a.TransactionId, a.CategoryId,
                a.Category?.Name, a.AnomalyType, a.Severity,
                a.Description, a.DetectedAt, a.IsFalsePositive));
    }

    public async Task<AnomalyDto?> AcknowledgeAnomalyAsync(int userId, int anomalyId, AcknowledgeAnomalyRequest req)
    {
        var a = await _db.Anomalies
            .Include(x => x.Category)
            .FirstOrDefaultAsync(x => x.AnomalyId == anomalyId && x.UserId == userId);

        if (a == null) return null;
        a.AcknowledgedAt = DateTime.UtcNow;
        a.IsFalsePositive = req.IsFalsePositive;
        await _db.SaveChangesAsync();

        return new AnomalyDto(a.AnomalyId, a.TransactionId, a.CategoryId,
            a.Category?.Name, a.AnomalyType, a.Severity,
            a.Description, a.DetectedAt, a.IsFalsePositive);
    }

    // ── PREDICTIONS ────────────────────────────────────────
    public async Task<IEnumerable<PredictionDto>> GetPredictionsAsync(int userId, int targetYear, int targetMonth)
    {
        return (await _db.ExpensePredictions
            .Include(p => p.Category)
            .Where(p => p.UserId == userId && p.TargetYear == targetYear && p.TargetMonth == targetMonth)
            .ToListAsync())
            .Select(p => new PredictionDto(
                p.CategoryId, p.Category?.Name,
                p.TargetYear, p.TargetMonth,
                p.PredictedAmount, p.ConfidenceLower, p.ConfidenceUpper, p.ModelName));
    }
}
