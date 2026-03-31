using FinanceApi.Models.DTOs;

namespace FinanceApi.Services.Interfaces;

public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(RegisterRequest req);
    Task<AuthResponse> LoginAsync(LoginRequest req);
}

public interface IUserService
{
    Task<UserDto?> GetByIdAsync(int userId);
    Task<UserDto> UpdateAsync(int userId, UpdateUserRequest req);
}

public interface ICategoryService
{
    Task<IEnumerable<CategoryDto>> GetAllAsync(int userId);
    Task<CategoryDto?> GetByIdAsync(int userId, int categoryId);
    Task<CategoryDto> CreateAsync(int userId, CreateCategoryRequest req);
    Task<CategoryDto?> UpdateAsync(int userId, int categoryId, UpdateCategoryRequest req);
    Task<bool> DeleteAsync(int userId, int categoryId);
}

public interface IAccountService
{
    Task<IEnumerable<AccountDto>> GetAllAsync(int userId);
    Task<AccountDto?> GetByIdAsync(int userId, int accountId);
    Task<AccountDto> CreateAsync(int userId, CreateAccountRequest req);
    Task<AccountDto?> UpdateAsync(int userId, int accountId, UpdateAccountRequest req);
    Task<bool> DeleteAsync(int userId, int accountId);
}

public interface ITagService
{
    Task<IEnumerable<TagDto>> GetAllAsync(int userId);
    Task<TagDto> CreateAsync(int userId, CreateTagRequest req);
    Task<bool> DeleteAsync(int userId, int tagId);
}

public interface ITransactionService
{
    Task<PagedResult<TransactionDto>> GetAllAsync(int userId, TransactionFilterRequest filter);
    Task<TransactionDto?> GetByIdAsync(int userId, int transactionId);
    Task<TransactionDto> CreateAsync(int userId, CreateTransactionRequest req);
    Task<TransactionDto?> UpdateAsync(int userId, int transactionId, UpdateTransactionRequest req);
    Task<bool> DeleteAsync(int userId, int transactionId);
}

public interface IBudgetService
{
    Task<IEnumerable<BudgetDto>> GetAllAsync(int userId);
    Task<BudgetDto?> GetByIdAsync(int userId, int budgetId);
    Task<BudgetDto> CreateAsync(int userId, CreateBudgetRequest req);
    Task<BudgetDto?> UpdateAsync(int userId, int budgetId, UpdateBudgetRequest req);
    Task<bool> DeleteAsync(int userId, int budgetId);
}

public interface IRecurringRuleService
{
    Task<IEnumerable<RecurringRuleDto>> GetAllAsync(int userId);
    Task<RecurringRuleDto?> GetByIdAsync(int userId, int ruleId);
    Task<RecurringRuleDto> CreateAsync(int userId, CreateRecurringRuleRequest req);
    Task<bool> DeactivateAsync(int userId, int ruleId);
}

public interface IAnalyticsService
{
    Task<IEnumerable<CategorySpendDto>> GetSpendByCategoryAsync(int userId, DateOnly? from, DateOnly? to);
    Task<IEnumerable<CategoryGrowthDto>> GetCategoryGrowthAsync(int userId, int months);
    Task<IEnumerable<FixedVariableSplitDto>> GetFixedVariableSplitAsync(int userId, int months);
    Task<IEnumerable<DailyTrendDto>> GetDailyTrendAsync(int userId, int days);
    Task<IEnumerable<BudgetAdherenceDto>> GetBudgetAdherenceAsync(int userId);
    Task<IEnumerable<SavingsRateDto>> GetSavingsRateAsync(int userId, int months);
    Task<ConsistencyScoreDto> GetConsistencyScoreAsync(int userId, int year, int month);
    Task<FinancialSnapshotDto?> GetSnapshotAsync(int userId, int year, int month);
    Task<IEnumerable<AnomalyDto>> GetAnomaliesAsync(int userId, bool includeFalsePositives);
    Task<AnomalyDto?> AcknowledgeAnomalyAsync(int userId, int anomalyId, AcknowledgeAnomalyRequest req);
    Task<IEnumerable<PredictionDto>> GetPredictionsAsync(int userId, int targetYear, int targetMonth);
}
