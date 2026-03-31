using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using FinanceApi.Data;
using FinanceApi.Models.DTOs;
using FinanceApi.Models.Entities;
using FinanceApi.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace FinanceApi.Services;

// ────────────────────── AUTH ──────────────────────
public class AuthService : IAuthService
{
    private readonly FinanceDbContext _db;
    private readonly IConfiguration _config;

    public AuthService(FinanceDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest req)
    {
        if (await _db.Users.AnyAsync(u => u.Email == req.Email))
            throw new InvalidOperationException("Email already registered.");

        var user = new User
        {
            Username = req.Username,
            Email = req.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.Password),
            Currency = req.Currency,
            MonthlyIncome = req.MonthlyIncome,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync();
        return GenerateToken(user);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest req)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == req.Email)
            ?? throw new UnauthorizedAccessException("Invalid credentials.");

        if (!BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            throw new UnauthorizedAccessException("Invalid credentials.");

        return GenerateToken(user);
    }

    private AuthResponse GenerateToken(User user)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expiryHours = int.Parse(_config["Jwt:ExpiryHours"] ?? "24");
        var expiry = DateTime.UtcNow.AddHours(expiryHours);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.Username)
        };

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: expiry,
            signingCredentials: creds);

        return new AuthResponse(
            new JwtSecurityTokenHandler().WriteToken(token),
            user.Username, user.Email, expiry);
    }
}

// ────────────────────── USER ──────────────────────
public class UserService : IUserService
{
    private readonly FinanceDbContext _db;

    public UserService(FinanceDbContext db) => _db = db;

    public async Task<UserDto?> GetByIdAsync(int userId)
    {
        var u = await _db.Users.FindAsync(userId);
        return u == null ? null : ToDto(u);
    }

    public async Task<UserDto> UpdateAsync(int userId, UpdateUserRequest req)
    {
        var u = await _db.Users.FindAsync(userId) ?? throw new KeyNotFoundException();
        if (req.Currency != null) u.Currency = req.Currency;
        if (req.MonthlyIncome.HasValue) u.MonthlyIncome = req.MonthlyIncome;
        u.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return ToDto(u);
    }

    private static UserDto ToDto(User u) =>
        new(u.UserId, u.Username, u.Email, u.Currency, u.MonthlyIncome, u.CreatedAt);
}

// ────────────────────── CATEGORY ──────────────────────
public class CategoryService : ICategoryService
{
    private readonly FinanceDbContext _db;
    public CategoryService(FinanceDbContext db) => _db = db;

    public async Task<IEnumerable<CategoryDto>> GetAllAsync(int userId)
    {
        var cats = await _db.Categories
            .Where(c => c.UserId == null || c.UserId == userId)
            .Include(c => c.Children)
            .ToListAsync();

        return cats.Where(c => c.ParentId == null).Select(MapDto);
    }

    public async Task<CategoryDto?> GetByIdAsync(int userId, int id)
    {
        var c = await _db.Categories.Include(x => x.Children)
            .FirstOrDefaultAsync(x => x.CategoryId == id && (x.UserId == null || x.UserId == userId));
        return c == null ? null : MapDto(c);
    }

    public async Task<CategoryDto> CreateAsync(int userId, CreateCategoryRequest req)
    {
        var cat = new Category
        {
            UserId = userId, ParentId = req.ParentId, Name = req.Name,
            Icon = req.Icon, Color = req.Color, ExpenseType = req.ExpenseType,
            IsSystem = false, CreatedAt = DateTime.UtcNow
        };
        _db.Categories.Add(cat);
        await _db.SaveChangesAsync();
        return MapDto(cat);
    }

    public async Task<CategoryDto?> UpdateAsync(int userId, int id, UpdateCategoryRequest req)
    {
        var cat = await _db.Categories.FirstOrDefaultAsync(c => c.CategoryId == id && c.UserId == userId);
        if (cat == null) return null;
        if (req.Name != null) cat.Name = req.Name;
        if (req.Icon != null) cat.Icon = req.Icon;
        if (req.Color != null) cat.Color = req.Color;
        if (req.ExpenseType != null) cat.ExpenseType = req.ExpenseType;
        await _db.SaveChangesAsync();
        return MapDto(cat);
    }

    public async Task<bool> DeleteAsync(int userId, int id)
    {
        var cat = await _db.Categories.FirstOrDefaultAsync(c => c.CategoryId == id && c.UserId == userId && !c.IsSystem);
        if (cat == null) return false;
        _db.Categories.Remove(cat);
        await _db.SaveChangesAsync();
        return true;
    }

    private static CategoryDto MapDto(Category c) => new(
        c.CategoryId, c.UserId, c.ParentId, c.Name, c.Icon, c.Color,
        c.ExpenseType, c.IsSystem,
        c.Children.Any() ? c.Children.Select(MapDto).ToList() : null);
}

// ────────────────────── ACCOUNT ──────────────────────
public class AccountService : IAccountService
{
    private readonly FinanceDbContext _db;
    public AccountService(FinanceDbContext db) => _db = db;

    public async Task<IEnumerable<AccountDto>> GetAllAsync(int userId) =>
        (await _db.Accounts.Where(a => a.UserId == userId && a.IsActive).ToListAsync()).Select(ToDto);

    public async Task<AccountDto?> GetByIdAsync(int userId, int id)
    {
        var a = await _db.Accounts.FirstOrDefaultAsync(x => x.AccountId == id && x.UserId == userId);
        return a == null ? null : ToDto(a);
    }

    public async Task<AccountDto> CreateAsync(int userId, CreateAccountRequest req)
    {
        var a = new Account
        {
            UserId = userId, Name = req.Name, AccountType = req.AccountType,
            Balance = req.Balance, CreditLimit = req.CreditLimit,
            Currency = req.Currency, Institution = req.Institution,
            IsActive = true, CreatedAt = DateTime.UtcNow
        };
        _db.Accounts.Add(a);
        await _db.SaveChangesAsync();
        return ToDto(a);
    }

    public async Task<AccountDto?> UpdateAsync(int userId, int id, UpdateAccountRequest req)
    {
        var a = await _db.Accounts.FirstOrDefaultAsync(x => x.AccountId == id && x.UserId == userId);
        if (a == null) return null;
        if (req.Name != null) a.Name = req.Name;
        if (req.Balance.HasValue) a.Balance = req.Balance.Value;
        if (req.Institution != null) a.Institution = req.Institution;
        if (req.IsActive.HasValue) a.IsActive = req.IsActive.Value;
        await _db.SaveChangesAsync();
        return ToDto(a);
    }

    public async Task<bool> DeleteAsync(int userId, int id)
    {
        var a = await _db.Accounts.FirstOrDefaultAsync(x => x.AccountId == id && x.UserId == userId);
        if (a == null) return false;
        a.IsActive = false;
        await _db.SaveChangesAsync();
        return true;
    }

    private static AccountDto ToDto(Account a) =>
        new(a.AccountId, a.Name, a.AccountType, a.Balance, a.CreditLimit,
            a.Currency, a.Institution, a.IsActive, a.CreatedAt);
}

// ────────────────────── TAG ──────────────────────
public class TagService : ITagService
{
    private readonly FinanceDbContext _db;
    public TagService(FinanceDbContext db) => _db = db;

    public async Task<IEnumerable<TagDto>> GetAllAsync(int userId) =>
        (await _db.Tags.Where(t => t.UserId == userId).ToListAsync())
        .Select(t => new TagDto(t.TagId, t.Name));

    public async Task<TagDto> CreateAsync(int userId, CreateTagRequest req)
    {
        var tag = new Tag { UserId = userId, Name = req.Name.ToLower().Trim() };
        _db.Tags.Add(tag);
        await _db.SaveChangesAsync();
        return new TagDto(tag.TagId, tag.Name);
    }

    public async Task<bool> DeleteAsync(int userId, int tagId)
    {
        var tag = await _db.Tags.FirstOrDefaultAsync(t => t.TagId == tagId && t.UserId == userId);
        if (tag == null) return false;
        _db.Tags.Remove(tag);
        await _db.SaveChangesAsync();
        return true;
    }
}
