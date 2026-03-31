using FinanceApi.Models.DTOs;
using FluentValidation;

namespace FinanceApi.Validators;

public class RegisterValidator : AbstractValidator<RegisterRequest>
{
    public RegisterValidator()
    {
        RuleFor(x => x.Username).NotEmpty().MinimumLength(3).MaximumLength(100);
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
        RuleFor(x => x.Password).NotEmpty().MinimumLength(8);
        RuleFor(x => x.Currency).NotEmpty().Length(3);
        RuleFor(x => x.MonthlyIncome).GreaterThan(0).When(x => x.MonthlyIncome.HasValue);
    }
}

public class LoginValidator : AbstractValidator<LoginRequest>
{
    public LoginValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
        RuleFor(x => x.Password).NotEmpty();
    }
}

public class CreateTransactionValidator : AbstractValidator<CreateTransactionRequest>
{
    private static readonly string[] ValidTypes = { "EXPENSE", "INCOME", "TRANSFER", "REFUND", "INVESTMENT" };

    public CreateTransactionValidator()
    {
        RuleFor(x => x.AccountId).GreaterThan(0);
        RuleFor(x => x.Amount).GreaterThan(0);
        RuleFor(x => x.Currency).NotEmpty().Length(3);
        RuleFor(x => x.TransactionType).Must(t => ValidTypes.Contains(t))
            .WithMessage($"TransactionType must be one of: {string.Join(", ", ValidTypes)}");
    }
}

public class CreateBudgetValidator : AbstractValidator<CreateBudgetRequest>
{
    private static readonly string[] ValidPeriods = { "WEEKLY", "MONTHLY", "QUARTERLY", "YEARLY", "CUSTOM" };

    public CreateBudgetValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.BudgetedAmount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.PeriodType).Must(p => ValidPeriods.Contains(p))
            .WithMessage($"PeriodType must be one of: {string.Join(", ", ValidPeriods)}");
        RuleFor(x => x.PeriodEnd).GreaterThan(x => x.PeriodStart)
            .WithMessage("PeriodEnd must be after PeriodStart");
        RuleFor(x => x.AlertThreshold).InclusiveBetween(0, 100);
    }
}

public class CreateAccountValidator : AbstractValidator<CreateAccountRequest>
{
    private static readonly string[] ValidTypes = { "CHECKING", "SAVINGS", "CREDIT_CARD", "CASH", "INVESTMENT", "LOAN" };

    public CreateAccountValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.AccountType).Must(t => ValidTypes.Contains(t))
            .WithMessage($"AccountType must be one of: {string.Join(", ", ValidTypes)}");
        RuleFor(x => x.Currency).NotEmpty().Length(3);
    }
}

public class CreateCategoryValidator : AbstractValidator<CreateCategoryRequest>
{
    private static readonly string[] ValidTypes = { "FIXED", "VARIABLE", "SEMI_VARIABLE" };

    public CreateCategoryValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.ExpenseType).Must(t => ValidTypes.Contains(t))
            .WithMessage($"ExpenseType must be one of: {string.Join(", ", ValidTypes)}");
        RuleFor(x => x.Color).Matches(@"^#[0-9A-Fa-f]{6}$")
            .When(x => x.Color != null)
            .WithMessage("Color must be a valid hex code (e.g. #FF5733)");
    }
}
