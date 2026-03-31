using System.Security.Claims;
using FinanceApi.Models.DTOs;
using FinanceApi.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FinanceApi.Controllers;

// ─── BASE ──────────────────────────────────────────
[ApiController]
[Authorize]
public abstract class BaseController : ControllerBase
{
    protected int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}

// ─── AUTH ──────────────────────────────────────────
[Route("api/auth")]
[AllowAnonymous]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly IAuthService _auth;
    public AuthController(IAuthService auth) => _auth = auth;

    /// <summary>Register a new user account</summary>
    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest req)
    {
        var result = await _auth.RegisterAsync(req);
        return Ok(result);
    }

    /// <summary>Login and receive JWT token</summary>
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest req)
    {
        var result = await _auth.LoginAsync(req);
        return Ok(result);
    }
}

// ─── USERS ─────────────────────────────────────────
[Route("api/users")]
public class UsersController : BaseController
{
    private readonly IUserService _users;
    public UsersController(IUserService users) => _users = users;

    /// <summary>Get current user profile</summary>
    [HttpGet("me")]
    public async Task<ActionResult<UserDto>> Me()
    {
        var user = await _users.GetByIdAsync(CurrentUserId);
        return user == null ? NotFound() : Ok(user);
    }

    /// <summary>Update user settings</summary>
    [HttpPatch("me")]
    public async Task<ActionResult<UserDto>> Update([FromBody] UpdateUserRequest req) =>
        Ok(await _users.UpdateAsync(CurrentUserId, req));
}

// ─── CATEGORIES ────────────────────────────────────
[Route("api/categories")]
public class CategoriesController : BaseController
{
    private readonly ICategoryService _svc;
    public CategoriesController(ICategoryService svc) => _svc = svc;

    /// <summary>List all categories (system + user-defined)</summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CategoryDto>>> List() =>
        Ok(await _svc.GetAllAsync(CurrentUserId));

    /// <summary>Get single category</summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<CategoryDto>> Get(int id)
    {
        var cat = await _svc.GetByIdAsync(CurrentUserId, id);
        return cat == null ? NotFound() : Ok(cat);
    }

    /// <summary>Create a custom category</summary>
    [HttpPost]
    public async Task<ActionResult<CategoryDto>> Create([FromBody] CreateCategoryRequest req)
    {
        var cat = await _svc.CreateAsync(CurrentUserId, req);
        return CreatedAtAction(nameof(Get), new { id = cat.CategoryId }, cat);
    }

    /// <summary>Update a category</summary>
    [HttpPatch("{id}")]
    public async Task<ActionResult<CategoryDto>> Update(int id, [FromBody] UpdateCategoryRequest req)
    {
        var cat = await _svc.UpdateAsync(CurrentUserId, id, req);
        return cat == null ? NotFound() : Ok(cat);
    }

    /// <summary>Delete a user-defined category</summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id) =>
        await _svc.DeleteAsync(CurrentUserId, id) ? NoContent() : NotFound();
}

// ─── ACCOUNTS ──────────────────────────────────────
[Route("api/accounts")]
public class AccountsController : BaseController
{
    private readonly IAccountService _svc;
    public AccountsController(IAccountService svc) => _svc = svc;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<AccountDto>>> List() =>
        Ok(await _svc.GetAllAsync(CurrentUserId));

    [HttpGet("{id}")]
    public async Task<ActionResult<AccountDto>> Get(int id)
    {
        var a = await _svc.GetByIdAsync(CurrentUserId, id);
        return a == null ? NotFound() : Ok(a);
    }

    [HttpPost]
    public async Task<ActionResult<AccountDto>> Create([FromBody] CreateAccountRequest req)
    {
        var a = await _svc.CreateAsync(CurrentUserId, req);
        return CreatedAtAction(nameof(Get), new { id = a.AccountId }, a);
    }

    [HttpPatch("{id}")]
    public async Task<ActionResult<AccountDto>> Update(int id, [FromBody] UpdateAccountRequest req)
    {
        var a = await _svc.UpdateAsync(CurrentUserId, id, req);
        return a == null ? NotFound() : Ok(a);
    }

    /// <summary>Soft-delete (deactivate) an account</summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id) =>
        await _svc.DeleteAsync(CurrentUserId, id) ? NoContent() : NotFound();
}

// ─── TAGS ──────────────────────────────────────────
[Route("api/tags")]
public class TagsController : BaseController
{
    private readonly ITagService _svc;
    public TagsController(ITagService svc) => _svc = svc;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<TagDto>>> List() =>
        Ok(await _svc.GetAllAsync(CurrentUserId));

    [HttpPost]
    public async Task<ActionResult<TagDto>> Create([FromBody] CreateTagRequest req) =>
        Ok(await _svc.CreateAsync(CurrentUserId, req));

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id) =>
        await _svc.DeleteAsync(CurrentUserId, id) ? NoContent() : NotFound();
}

// ─── TRANSACTIONS ──────────────────────────────────
[Route("api/transactions")]
public class TransactionsController : BaseController
{
    private readonly ITransactionService _svc;
    public TransactionsController(ITransactionService svc) => _svc = svc;

    /// <summary>
    /// List transactions with filters:
    /// from, to (DateOnly), categoryId, accountId,
    /// transactionType (EXPENSE|INCOME|TRANSFER|REFUND|INVESTMENT),
    /// merchant, isExcluded, page, pageSize
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<PagedResult<TransactionDto>>> List([FromQuery] TransactionFilterRequest filter) =>
        Ok(await _svc.GetAllAsync(CurrentUserId, filter));

    [HttpGet("{id}")]
    public async Task<ActionResult<TransactionDto>> Get(int id)
    {
        var t = await _svc.GetByIdAsync(CurrentUserId, id);
        return t == null ? NotFound() : Ok(t);
    }

    [HttpPost]
    public async Task<ActionResult<TransactionDto>> Create([FromBody] CreateTransactionRequest req)
    {
        var t = await _svc.CreateAsync(CurrentUserId, req);
        return CreatedAtAction(nameof(Get), new { id = t.TransactionId }, t);
    }

    [HttpPatch("{id}")]
    public async Task<ActionResult<TransactionDto>> Update(int id, [FromBody] UpdateTransactionRequest req)
    {
        var t = await _svc.UpdateAsync(CurrentUserId, id, req);
        return t == null ? NotFound() : Ok(t);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id) =>
        await _svc.DeleteAsync(CurrentUserId, id) ? NoContent() : NotFound();
}

// ─── BUDGETS ───────────────────────────────────────
[Route("api/budgets")]
public class BudgetsController : BaseController
{
    private readonly IBudgetService _svc;
    public BudgetsController(IBudgetService svc) => _svc = svc;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<BudgetDto>>> List() =>
        Ok(await _svc.GetAllAsync(CurrentUserId));

    [HttpGet("{id}")]
    public async Task<ActionResult<BudgetDto>> Get(int id)
    {
        var b = await _svc.GetByIdAsync(CurrentUserId, id);
        return b == null ? NotFound() : Ok(b);
    }

    [HttpPost]
    public async Task<ActionResult<BudgetDto>> Create([FromBody] CreateBudgetRequest req)
    {
        var b = await _svc.CreateAsync(CurrentUserId, req);
        return CreatedAtAction(nameof(Get), new { id = b.BudgetId }, b);
    }

    [HttpPatch("{id}")]
    public async Task<ActionResult<BudgetDto>> Update(int id, [FromBody] UpdateBudgetRequest req)
    {
        var b = await _svc.UpdateAsync(CurrentUserId, id, req);
        return b == null ? NotFound() : Ok(b);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id) =>
        await _svc.DeleteAsync(CurrentUserId, id) ? NoContent() : NotFound();
}

// ─── RECURRING RULES ───────────────────────────────
[Route("api/recurring")]
public class RecurringController : BaseController
{
    private readonly IRecurringRuleService _svc;
    public RecurringController(IRecurringRuleService svc) => _svc = svc;

    [HttpGet]
    public async Task<ActionResult<IEnumerable<RecurringRuleDto>>> List() =>
        Ok(await _svc.GetAllAsync(CurrentUserId));

    [HttpGet("{id}")]
    public async Task<ActionResult<RecurringRuleDto>> Get(int id)
    {
        var r = await _svc.GetByIdAsync(CurrentUserId, id);
        return r == null ? NotFound() : Ok(r);
    }

    [HttpPost]
    public async Task<ActionResult<RecurringRuleDto>> Create([FromBody] CreateRecurringRuleRequest req)
    {
        var r = await _svc.CreateAsync(CurrentUserId, req);
        return CreatedAtAction(nameof(Get), new { id = r.RecurrenceId }, r);
    }

    /// <summary>Deactivate a recurring rule (stops future generation)</summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> Deactivate(int id) =>
        await _svc.DeactivateAsync(CurrentUserId, id) ? NoContent() : NotFound();
}

// ─── ANALYTICS ─────────────────────────────────────
[Route("api/analytics")]
public class AnalyticsController : BaseController
{
    private readonly IAnalyticsService _svc;
    public AnalyticsController(IAnalyticsService svc) => _svc = svc;

    /// <summary>
    /// Expense breakdown by category.
    /// Query: from (DateOnly), to (DateOnly) — defaults to current month
    /// </summary>
    [HttpGet("spend-by-category")]
    public async Task<ActionResult<IEnumerable<CategorySpendDto>>> SpendByCategory(
        [FromQuery] DateOnly? from, [FromQuery] DateOnly? to) =>
        Ok(await _svc.GetSpendByCategoryAsync(CurrentUserId, from, to));

    /// <summary>
    /// Month-over-month category growth rate.
    /// Query: months (default 6)
    /// </summary>
    [HttpGet("category-growth")]
    public async Task<ActionResult<IEnumerable<CategoryGrowthDto>>> CategoryGrowth(
        [FromQuery] int months = 6) =>
        Ok(await _svc.GetCategoryGrowthAsync(CurrentUserId, months));

    /// <summary>
    /// Fixed vs Variable vs Semi-variable split per month.
    /// Query: months (default 6)
    /// </summary>
    [HttpGet("fixed-variable-split")]
    public async Task<ActionResult<IEnumerable<FixedVariableSplitDto>>> FixedVariableSplit(
        [FromQuery] int months = 6) =>
        Ok(await _svc.GetFixedVariableSplitAsync(CurrentUserId, months));

    /// <summary>
    /// Daily spending trend with 7-day and 30-day rolling averages.
    /// Query: days (default 90)
    /// </summary>
    [HttpGet("daily-trend")]
    public async Task<ActionResult<IEnumerable<DailyTrendDto>>> DailyTrend(
        [FromQuery] int days = 90) =>
        Ok(await _svc.GetDailyTrendAsync(CurrentUserId, days));

    /// <summary>Budget adherence — highlights overspent budgets</summary>
    [HttpGet("budget-adherence")]
    public async Task<ActionResult<IEnumerable<BudgetAdherenceDto>>> BudgetAdherence() =>
        Ok(await _svc.GetBudgetAdherenceAsync(CurrentUserId));

    /// <summary>
    /// Savings rate, burn rate, runway, and prediction.
    /// Query: months (default 12)
    /// </summary>
    [HttpGet("savings-rate")]
    public async Task<ActionResult<IEnumerable<SavingsRateDto>>> SavingsRate(
        [FromQuery] int months = 12) =>
        Ok(await _svc.GetSavingsRateAsync(CurrentUserId, months));

    /// <summary>
    /// Spending consistency score (0–100) for a given month.
    /// Query: year, month
    /// </summary>
    [HttpGet("consistency-score")]
    public async Task<ActionResult<ConsistencyScoreDto>> ConsistencyScore(
        [FromQuery] int? year = null, [FromQuery] int? month = null) =>
        Ok(await _svc.GetConsistencyScoreAsync(
            CurrentUserId,
            year ?? DateTime.UtcNow.Year,
            month ?? DateTime.UtcNow.Month));

    /// <summary>
    /// Full financial snapshot (pre-computed) for a month.
    /// Query: year, month
    /// </summary>
    [HttpGet("snapshot")]
    public async Task<ActionResult<FinancialSnapshotDto>> Snapshot(
        [FromQuery] int? year = null, [FromQuery] int? month = null)
    {
        var s = await _svc.GetSnapshotAsync(
            CurrentUserId,
            year ?? DateTime.UtcNow.Year,
            month ?? DateTime.UtcNow.Month);
        return s == null ? NotFound() : Ok(s);
    }

    /// <summary>
    /// Detected anomalies (overspending, unusual transactions, etc.)
    /// Query: includeFalsePositives (default false)
    /// </summary>
    [HttpGet("anomalies")]
    public async Task<ActionResult<IEnumerable<AnomalyDto>>> Anomalies(
        [FromQuery] bool includeFalsePositives = false) =>
        Ok(await _svc.GetAnomaliesAsync(CurrentUserId, includeFalsePositives));

    /// <summary>Acknowledge or mark an anomaly as false positive</summary>
    [HttpPatch("anomalies/{id}/acknowledge")]
    public async Task<ActionResult<AnomalyDto>> AcknowledgeAnomaly(
        int id, [FromBody] AcknowledgeAnomalyRequest req)
    {
        var a = await _svc.AcknowledgeAnomalyAsync(CurrentUserId, id, req);
        return a == null ? NotFound() : Ok(a);
    }

    /// <summary>
    /// Predicted expenses for a target month.
    /// Query: targetYear, targetMonth
    /// </summary>
    [HttpGet("predictions")]
    public async Task<ActionResult<IEnumerable<PredictionDto>>> Predictions(
        [FromQuery] int? targetYear = null, [FromQuery] int? targetMonth = null)
    {
        var next = DateTime.UtcNow.AddMonths(1);
        return Ok(await _svc.GetPredictionsAsync(
            CurrentUserId,
            targetYear  ?? next.Year,
            targetMonth ?? next.Month));
    }
}
