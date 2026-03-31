using FinanceApi.Data;
using FinanceApi.Models.DTOs;
using FinanceApi.Models.Entities;
using FinanceApi.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace FinanceApi.Services;

// ────────────────────── TRANSACTION ──────────────────────
public class TransactionService : ITransactionService
{
    private readonly FinanceDbContext _db;
    public TransactionService(FinanceDbContext db) => _db = db;

    public async Task<PagedResult<TransactionDto>> GetAllAsync(int userId, TransactionFilterRequest f)
    {
        var q = _db.Transactions
            .Include(t => t.Category)
            .Include(t => t.Account)
            .Include(t => t.TransactionTags).ThenInclude(tt => tt.Tag)
            .Where(t => t.UserId == userId);

        if (f.From.HasValue)          q = q.Where(t => t.TransactionDate >= f.From.Value);
        if (f.To.HasValue)            q = q.Where(t => t.TransactionDate <= f.To.Value);
        if (f.CategoryId.HasValue)    q = q.Where(t => t.CategoryId == f.CategoryId);
        if (f.AccountId.HasValue)     q = q.Where(t => t.AccountId == f.AccountId);
        if (f.TransactionType != null) q = q.Where(t => t.TransactionType == f.TransactionType);
        if (f.Merchant != null)       q = q.Where(t => EF.Functions.ILike(t.Merchant!, $"%{f.Merchant}%"));
        if (f.IsExcluded.HasValue)    q = q.Where(t => t.IsExcluded == f.IsExcluded.Value);

        var total = await q.CountAsync();
        var items = await q
            .OrderByDescending(t => t.TransactionDate)
            .Skip((f.Page - 1) * f.PageSize)
            .Take(f.PageSize)
            .ToListAsync();

        return new PagedResult<TransactionDto>(
            items.Select(ToDto),
            total, f.Page, f.PageSize,
            (int)Math.Ceiling(total / (double)f.PageSize));
    }

    public async Task<TransactionDto?> GetByIdAsync(int userId, int id)
    {
        var t = await _db.Transactions
            .Include(x => x.Category).Include(x => x.Account)
            .Include(x => x.TransactionTags).ThenInclude(tt => tt.Tag)
            .FirstOrDefaultAsync(x => x.TransactionId == id && x.UserId == userId);
        return t == null ? null : ToDto(t);
    }

    public async Task<TransactionDto> CreateAsync(int userId, CreateTransactionRequest req)
    {
        var txn = new Transaction
        {
            UserId = userId,
            AccountId = req.AccountId,
            CategoryId = req.CategoryId,
            Amount = req.Amount,
            Currency = req.Currency,
            TransactionType = req.TransactionType,
            IsRecurring = req.IsRecurring,
            RecurrenceId = req.RecurrenceId,
            Merchant = req.Merchant,
            Description = req.Description,
            Notes = req.Notes,
            TransactionDate = req.TransactionDate ?? DateOnly.FromDateTime(DateTime.UtcNow),
            PostedDate = req.PostedDate,
            Latitude = req.Latitude,
            Longitude = req.Longitude,
            City = req.City,
            Country = req.Country,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _db.Transactions.Add(txn);
        await _db.SaveChangesAsync();

        if (req.TagIds?.Any() == true)
        {
            foreach (var tagId in req.TagIds)
                _db.TransactionTags.Add(new TransactionTag { TransactionId = txn.TransactionId, TagId = tagId });
            await _db.SaveChangesAsync();
        }

        return (await GetByIdAsync(userId, txn.TransactionId))!;
    }

    public async Task<TransactionDto?> UpdateAsync(int userId, int id, UpdateTransactionRequest req)
    {
        var txn = await _db.Transactions.FirstOrDefaultAsync(t => t.TransactionId == id && t.UserId == userId);
        if (txn == null) return null;

        if (req.CategoryId.HasValue)     txn.CategoryId = req.CategoryId;
        if (req.Amount.HasValue)         txn.Amount = req.Amount.Value;
        if (req.Merchant != null)        txn.Merchant = req.Merchant;
        if (req.Description != null)     txn.Description = req.Description;
        if (req.Notes != null)           txn.Notes = req.Notes;
        if (req.TransactionDate.HasValue) txn.TransactionDate = req.TransactionDate.Value;
        if (req.IsVerified.HasValue)     txn.IsVerified = req.IsVerified.Value;
        if (req.IsExcluded.HasValue)     txn.IsExcluded = req.IsExcluded.Value;
        txn.UpdatedAt = DateTime.UtcNow;

        if (req.TagIds != null)
        {
            var existing = _db.TransactionTags.Where(tt => tt.TransactionId == id);
            _db.TransactionTags.RemoveRange(existing);
            foreach (var tagId in req.TagIds)
                _db.TransactionTags.Add(new TransactionTag { TransactionId = id, TagId = tagId });
        }

        await _db.SaveChangesAsync();
        return await GetByIdAsync(userId, id);
    }

    public async Task<bool> DeleteAsync(int userId, int id)
    {
        var txn = await _db.Transactions.FirstOrDefaultAsync(t => t.TransactionId == id && t.UserId == userId);
        if (txn == null) return false;
        _db.Transactions.Remove(txn);
        await _db.SaveChangesAsync();
        return true;
    }

    private static TransactionDto ToDto(Transaction t) => new(
        t.TransactionId, t.AccountId, t.CategoryId,
        t.Category?.Name, t.Account?.Name,
        t.Amount, t.Currency, t.TransactionType,
        t.IsRecurring, t.Merchant, t.Description, t.Notes,
        t.TransactionDate, t.PostedDate,
        t.City, t.Country, t.IsVerified, t.IsExcluded,
        t.TransactionTags.Select(tt => new TagDto(tt.Tag.TagId, tt.Tag.Name)).ToList(),
        t.CreatedAt);
}

// ────────────────────── BUDGET ──────────────────────
public class BudgetService : IBudgetService
{
    private readonly FinanceDbContext _db;
    public BudgetService(FinanceDbContext db) => _db = db;

    public async Task<IEnumerable<BudgetDto>> GetAllAsync(int userId)
    {
        var budgets = await _db.Budgets
            .Include(b => b.Category)
            .Where(b => b.UserId == userId && b.IsActive)
            .ToListAsync();

        var result = new List<BudgetDto>();
        foreach (var b in budgets)
            result.Add(await EnrichBudget(b));
        return result;
    }

    public async Task<BudgetDto?> GetByIdAsync(int userId, int id)
    {
        var b = await _db.Budgets.Include(x => x.Category)
            .FirstOrDefaultAsync(x => x.BudgetId == id && x.UserId == userId);
        return b == null ? null : await EnrichBudget(b);
    }

    public async Task<BudgetDto> CreateAsync(int userId, CreateBudgetRequest req)
    {
        var b = new Budget
        {
            UserId = userId, CategoryId = req.CategoryId, Name = req.Name,
            PeriodType = req.PeriodType, PeriodStart = req.PeriodStart, PeriodEnd = req.PeriodEnd,
            BudgetedAmount = req.BudgetedAmount, Rollover = req.Rollover,
            AlertThreshold = req.AlertThreshold, IsActive = true, CreatedAt = DateTime.UtcNow
        };
        _db.Budgets.Add(b);
        await _db.SaveChangesAsync();
        return await EnrichBudget(b);
    }

    public async Task<BudgetDto?> UpdateAsync(int userId, int id, UpdateBudgetRequest req)
    {
        var b = await _db.Budgets.Include(x => x.Category)
            .FirstOrDefaultAsync(x => x.BudgetId == id && x.UserId == userId);
        if (b == null) return null;
        if (req.Name != null) b.Name = req.Name;
        if (req.BudgetedAmount.HasValue) b.BudgetedAmount = req.BudgetedAmount.Value;
        if (req.AlertThreshold.HasValue) b.AlertThreshold = req.AlertThreshold.Value;
        if (req.IsActive.HasValue) b.IsActive = req.IsActive.Value;
        await _db.SaveChangesAsync();
        return await EnrichBudget(b);
    }

    public async Task<bool> DeleteAsync(int userId, int id)
    {
        var b = await _db.Budgets.FirstOrDefaultAsync(x => x.BudgetId == id && x.UserId == userId);
        if (b == null) return false;
        b.IsActive = false;
        await _db.SaveChangesAsync();
        return true;
    }

    private async Task<BudgetDto> EnrichBudget(Budget b)
    {
        var spent = await _db.Transactions
            .Where(t => t.UserId == b.UserId
                && (b.CategoryId == null || t.CategoryId == b.CategoryId)
                && t.TransactionDate >= b.PeriodStart
                && t.TransactionDate <= b.PeriodEnd
                && t.TransactionType == "EXPENSE"
                && !t.IsExcluded)
            .SumAsync(t => (decimal?)t.Amount) ?? 0;

        var remaining = b.BudgetedAmount - spent;
        var pct = b.BudgetedAmount > 0 ? Math.Round(spent / b.BudgetedAmount * 100, 2) : 0;

        return new BudgetDto(b.BudgetId, b.CategoryId, b.Category?.Name, b.Name,
            b.PeriodType, b.PeriodStart, b.PeriodEnd,
            b.BudgetedAmount, spent, remaining, pct, spent > b.BudgetedAmount, b.IsActive);
    }
}

// ────────────────────── RECURRING RULES ──────────────────────
public class RecurringRuleService : IRecurringRuleService
{
    private readonly FinanceDbContext _db;
    public RecurringRuleService(FinanceDbContext db) => _db = db;

    public async Task<IEnumerable<RecurringRuleDto>> GetAllAsync(int userId) =>
        (await _db.RecurringRules.Where(r => r.UserId == userId).ToListAsync()).Select(ToDto);

    public async Task<RecurringRuleDto?> GetByIdAsync(int userId, int id)
    {
        var r = await _db.RecurringRules.FirstOrDefaultAsync(x => x.RecurrenceId == id && x.UserId == userId);
        return r == null ? null : ToDto(r);
    }

    public async Task<RecurringRuleDto> CreateAsync(int userId, CreateRecurringRuleRequest req)
    {
        var r = new RecurringRule
        {
            UserId = userId, AccountId = req.AccountId, CategoryId = req.CategoryId,
            TransactionType = req.TransactionType, Amount = req.Amount,
            Description = req.Description, Frequency = req.Frequency,
            StartDate = req.StartDate, EndDate = req.EndDate,
            IsActive = true, CreatedAt = DateTime.UtcNow
        };
        _db.RecurringRules.Add(r);
        await _db.SaveChangesAsync();
        return ToDto(r);
    }

    public async Task<bool> DeactivateAsync(int userId, int id)
    {
        var r = await _db.RecurringRules.FirstOrDefaultAsync(x => x.RecurrenceId == id && x.UserId == userId);
        if (r == null) return false;
        r.IsActive = false;
        await _db.SaveChangesAsync();
        return true;
    }

    private static RecurringRuleDto ToDto(RecurringRule r) => new(
        r.RecurrenceId, r.AccountId, r.CategoryId,
        r.TransactionType, r.Amount, r.Description,
        r.Frequency, r.StartDate, r.EndDate, r.IsActive);
}
