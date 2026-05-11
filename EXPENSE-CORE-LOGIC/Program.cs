using ExpenseAPI.BusinessLogic.Data;
using ExpenseAPI.BusinessLogic.Services;
using ExpenseAPI.BusinessLogic.Middleware;
using Microsoft.EntityFrameworkCore;
using Serilog;
using System.Data.SqlTypes;

var builder = WebApplication.CreateBuilder(args);
// ___Logging___
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File("logs/business-logic-.log", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();


// ___Database___
var connStr = builder.Configuration.GetConnectionString("DefaultConnection");
    ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

builder.Services.AddDbContext<ExpenseDbContext>(opt => 
    opt.UseSqlServer(connStr, sql => sql.EnableRetryOnFailure(maxRetryCount: 5)));

// ___Domain Services___
builder.Services.AddScoped<ITransactionService, TransactionService>();
builder.Services.AddScoped<IBudgetService,      BudgetService>();
builder.Services.AddScoped<IAccountService,     AccountService>();
builder.Services.AddScoped<ICategoryService,    CategoryService>();
builder.Services.AddScoped<IAuditService,       AuditService>();
builder.Services.AddScoped<IValidationService,  ValidationService>();
 
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "ExpenseAPI.BusinessLogic", Version = "v1" });
});

var app = builder.Build();

// ___Middleware___
// Order matters! Each request goes through these in order.
app.UseMiddleware<InternalAuthMiddleware>(); // 1. Verify request came from gateway
app.UseSerilogRequestLogging();  // 2. Log every request
// (controllers handle audit logging themselves via IAuditService)

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "ExpenseAPI.BusinessLogic v1"));
}

app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "Healthy", timestamp = DateTime.UtcNow, service = "ExpenseAPI.BusinessLogic" }));

app.Run();