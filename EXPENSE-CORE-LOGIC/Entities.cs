using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ExpenseAPI.BusinessLogic.Models;
[Table("users", Schema = "dbo")]
public class User
{
    [Key, Column("user_id")]                 public int      UserId       { get; set; }
    [Column("username")]                     public string   Username     { get; set; } = null!;
    [Column("email")]                        public string   Email        { get; set; } = null!;
    [Column("password_hash")]                public string   PasswordHash { get; set; } = null!;
    [Column("full_name")]                    public string?  FullName     { get; set; }
    [Column("role")]                         public string   Role         { get; set; } = "user";
    [Column("is_active")]                    public bool     IsActive     { get; set; } = true;
    [Column("last_login")]                   public DateTime? LastLogin   { get; set; }
    [Column("currency")]                     public string   Currency     { get; set; } = "USD";
    [Column("created_at")]                   public DateTime CreatedAt    { get; set; }
    [Column("updated_at")]                   public DateTime UpdatedAt    { get; set; }
 
    public ICollection<Account>     Accounts     { get; set; } = new List<Account>();
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
    public ICollection<Budget>      Budgets      { get; set; } = new List<Budget>();
}
 
[Table("categories", Schema = "dbo")]
public class Category
{
    [Key, Column("category_id")]             public int      CategoryId  { get; set; }
    [Column("user_id")]                      public int?     UserId      { get; set; }
    [Column("parent_id")]                    public int?     ParentId    { get; set; }
    [Column("name")]                         public string   Name        { get; set; } = null!;
    [Column("icon")]                         public string?  Icon        { get; set; }
    [Column("color")]                        public string?  Color       { get; set; }
    [Column("expense_type")]                 public string   ExpenseType { get; set; } = "variable";
    [Column("is_system")]                    public bool     IsSystem    { get; set; }
    [Column("created_at")]                   public DateTime CreatedAt   { get; set; }
    [Column("updated_at")]                   public DateTime UpdatedAt   { get; set; }
 
    public User?     User   { get; set; }
    public Category? Parent { get; set; }
}
 
[Table("accounts", Schema = "dbo")]
public class Account
{
    [Key, Column("account_id")]              public int      AccountId   { get; set; }
    [Column("user_id")]                      public int      UserId      { get; set; }
    [Column("name")]                         public string   Name        { get; set; } = null!;
    [Column("account_type")]                 public string   AccountType { get; set; } = null!;
    [Column("balance")]                      public decimal  Balance     { get; set; }
    [Column("credit_limit")]                 public decimal? CreditLimit { get; set; }
    [Column("currency")]                     public string   Currency    { get; set; } = "VND";
    [Column("institution")]                  public string?  Institution { get; set; }
    [Column("is_active")]                    public bool     IsActive    { get; set; } = true;
    [Column("created_at")]                   public DateTime CreatedAt   { get; set; }
 
    public User? User { get; set; }
}
 
[Table("transactions", Schema = "dbo")]
public class Transaction
{
    [Key, Column("transaction_id")]          public int       TransactionId      { get; set; }
    [Column("user_id")]                      public int       UserId             { get; set; }
    [Column("account_id")]                   public int       AccountId          { get; set; }
    [Column("category_id")]                  public int?      CategoryId         { get; set; }
    [Column("amount")]                       public decimal   Amount             { get; set; }
    [Column("currency")]                     public string    Currency           { get; set; } = "VND";
    [Column("amount_base_currency")]         public decimal?  AmountBaseCurrency { get; set; }
    [Column("exchange_rate")]                public decimal?  ExchangeRate       { get; set; }
    [Column("transaction_type")]             public string    TransactionType    { get; set; } = null!;
    [Column("is_recurring")]                 public bool      IsRecurring        { get; set; }
    [Column("recurrence_id")]                public int?      RecurrenceId       { get; set; }
    [Column("merchant")]                     public string?   Merchant           { get; set; }
    [Column("description")]                  public string?   Description        { get; set; }
    [Column("notes")]                        public string?   Notes              { get; set; }
    [Column("transaction_date")]             public DateTime  TransactionDate    { get; set; }
    [Column("posted_date")]                  public DateTime? PostedDate         { get; set; }
    [Column("latitude")]                     public decimal?  Latitude           { get; set; }
    [Column("longitude")]                    public decimal?  Longitude          { get; set; }
    [Column("city")]                         public string?   City               { get; set; }
    [Column("country")]                      public string?   Country            { get; set; }
    [Column("is_verified")]                  public bool      IsVerified         { get; set; }
    [Column("is_excluded")]                  public bool      IsExcluded         { get; set; }
    [Column("created_at")]                   public DateTime  CreatedAt          { get; set; }
    [Column("updated_at")]                   public DateTime  UpdatedAt          { get; set; }
 
    public User?     User     { get; set; }
    public Account?  Account  { get; set; }
    public Category? Category { get; set; }
}
 
[Table("budgets", Schema = "dbo")]
public class Budget
{
    [Key, Column("budget_id")]               public int      BudgetId       { get; set; }
    [Column("user_id")]                      public int      UserId         { get; set; }
    [Column("category_id")]                  public int?     CategoryId     { get; set; }
    [Column("name")]                         public string   Name           { get; set; } = null!;
    [Column("period_type")]                  public string   PeriodType     { get; set; } = "MONTHLY";
    [Column("period_start")]                 public DateTime PeriodStart    { get; set; }
    [Column("period_end")]                   public DateTime PeriodEnd      { get; set; }
    [Column("budget_amount")]                public decimal  BudgetAmount   { get; set; }
    [Column("rollover")]                     public bool     Rollover       { get; set; }
    [Column("alert_threshold")]              public decimal  AlertThreshold { get; set; } = 80m;
    [Column("is_active")]                    public bool     IsActive       { get; set; } = true;
    [Column("created_at")]                   public DateTime CreatedAt      { get; set; }
 
    public Category? Category { get; set; }
}
 
[Table("audit_logs", Schema = "dbo")]
public class AuditLog
{
    [Key, Column("audit_id")]                public long     AuditId    { get; set; }
    [Column("user_id")]                      public int?     UserId     { get; set; }
    [Column("action")]                       public string   Action     { get; set; } = null!;
    [Column("table_name")]                   public string   TableName  { get; set; } = null!;
    [Column("record_id")]                    public int?     RecordId   { get; set; }
    [Column("old_values")]                   public string?  OldValues  { get; set; }
    [Column("new_values")]                   public string?  NewValues  { get; set; }
    [Column("ip_address")]                   public string?  IpAddress  { get; set; }
    [Column("user_agent")]                   public string?  UserAgent  { get; set; }
    [Column("created_at")]                   public DateTime CreatedAt  { get; set; }
}
 
[Table("anomalies", Schema = "dbo")]
public class Anomaly
{
    [Key, Column("anomaly_id")]              public int      AnomalyId       { get; set; }
    [Column("user_id")]                      public int      UserId          { get; set; }
    [Column("transaction_id")]               public int?     TransactionId   { get; set; }
    [Column("category_id")]                  public int?     CategoryId      { get; set; }
    [Column("anomaly_type")]                 public string   AnomalyType     { get; set; } = null!;
    [Column("severity")]                     public string   Severity        { get; set; } = "MEDIUM";
    [Column("description")]                  public string?  Description     { get; set; }
    [Column("detected_at")]                  public DateTime DetectedAt      { get; set; }
    [Column("acknowledged_at")]              public DateTime? AcknowledgedAt { get; set; }
    [Column("is_false_positive")]            public bool     IsFalsePositive { get; set; }
}
[Table("users", Schema = "dbo")]
public class User
{
    [Key, Column("user_id")]                 public int      UserId       { get; set; }
    [Column("username")]                     public string   Username     { get; set; } = null!;
    [Column("email")]                        public string   Email        { get; set; } = null!;
    [Column("password_hash")]                public string   PasswordHash { get; set; } = null!;
    [Column("full_name")]                    public string?  FullName     { get; set; }
    [Column("role")]                         public string   Role         { get; set; } = "user";
    [Column("is_active")]                    public bool     IsActive     { get; set; } = true;
    [Column("last_login")]                   public DateTime? LastLogin   { get; set; }
    [Column("currency")]                     public string   Currency     { get; set; } = "USD";
    [Column("created_at")]                   public DateTime CreatedAt    { get; set; }
    [Column("updated_at")]                   public DateTime UpdatedAt    { get; set; }
 
    public ICollection<Account>     Accounts     { get; set; } = new List<Account>();
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
    public ICollection<Budget>      Budgets      { get; set; } = new List<Budget>();
}
 
[Table("categories", Schema = "dbo")]
public class Category
{
    [Key, Column("category_id")]             public int      CategoryId  { get; set; }
    [Column("user_id")]                      public int?     UserId      { get; set; }
    [Column("parent_id")]                    public int?     ParentId    { get; set; }
    [Column("name")]                         public string   Name        { get; set; } = null!;
    [Column("icon")]                         public string?  Icon        { get; set; }
    [Column("color")]                        public string?  Color       { get; set; }
    [Column("expense_type")]                 public string   ExpenseType { get; set; } = "variable";
    [Column("is_system")]                    public bool     IsSystem    { get; set; }
    [Column("created_at")]                   public DateTime CreatedAt   { get; set; }
    [Column("updated_at")]                   public DateTime UpdatedAt   { get; set; }
 
    public User?     User   { get; set; }
    public Category? Parent { get; set; }
}
 
[Table("accounts", Schema = "dbo")]
public class Account
{
    [Key, Column("account_id")]              public int      AccountId   { get; set; }
    [Column("user_id")]                      public int      UserId      { get; set; }
    [Column("name")]                         public string   Name        { get; set; } = null!;
    [Column("account_type")]                 public string   AccountType { get; set; } = null!;
    [Column("balance")]                      public decimal  Balance     { get; set; }
    [Column("credit_limit")]                 public decimal? CreditLimit { get; set; }
    [Column("currency")]                     public string   Currency    { get; set; } = "VND";
    [Column("institution")]                  public string?  Institution { get; set; }
    [Column("is_active")]                    public bool     IsActive    { get; set; } = true;
    [Column("created_at")]                   public DateTime CreatedAt   { get; set; }
 
    public User? User { get; set; }
}
 
[Table("transactions", Schema = "dbo")]
public class Transaction
{
    [Key, Column("transaction_id")]          public int       TransactionId      { get; set; }
    [Column("user_id")]                      public int       UserId             { get; set; }
    [Column("account_id")]                   public int       AccountId          { get; set; }
    [Column("category_id")]                  public int?      CategoryId         { get; set; }
    [Column("amount")]                       public decimal   Amount             { get; set; }
    [Column("currency")]                     public string    Currency           { get; set; } = "VND";
    [Column("amount_base_currency")]         public decimal?  AmountBaseCurrency { get; set; }
    [Column("exchange_rate")]                public decimal?  ExchangeRate       { get; set; }
    [Column("transaction_type")]             public string    TransactionType    { get; set; } = null!;
    [Column("is_recurring")]                 public bool      IsRecurring        { get; set; }
    [Column("recurrence_id")]                public int?      RecurrenceId       { get; set; }
    [Column("merchant")]                     public string?   Merchant           { get; set; }
    [Column("description")]                  public string?   Description        { get; set; }
    [Column("notes")]                        public string?   Notes              { get; set; }
    [Column("transaction_date")]             public DateTime  TransactionDate    { get; set; }
    [Column("posted_date")]                  public DateTime? PostedDate         { get; set; }
    [Column("latitude")]                     public decimal?  Latitude           { get; set; }
    [Column("longitude")]                    public decimal?  Longitude          { get; set; }
    [Column("city")]                         public string?   City               { get; set; }
    [Column("country")]                      public string?   Country            { get; set; }
    [Column("is_verified")]                  public bool      IsVerified         { get; set; }
    [Column("is_excluded")]                  public bool      IsExcluded         { get; set; }
    [Column("created_at")]                   public DateTime  CreatedAt          { get; set; }
    [Column("updated_at")]                   public DateTime  UpdatedAt          { get; set; }
 
    public User?     User     { get; set; }
    public Account?  Account  { get; set; }
    public Category? Category { get; set; }
}
 
[Table("budgets", Schema = "dbo")]
public class Budget
{
    [Key, Column("budget_id")]               public int      BudgetId       { get; set; }
    [Column("user_id")]                      public int      UserId         { get; set; }
    [Column("category_id")]                  public int?     CategoryId     { get; set; }
    [Column("name")]                         public string   Name           { get; set; } = null!;
    [Column("period_type")]                  public string   PeriodType     { get; set; } = "MONTHLY";
    [Column("period_start")]                 public DateTime PeriodStart    { get; set; }
    [Column("period_end")]                   public DateTime PeriodEnd      { get; set; }
    [Column("budget_amount")]                public decimal  BudgetAmount   { get; set; }
    [Column("rollover")]                     public bool     Rollover       { get; set; }
    [Column("alert_threshold")]              public decimal  AlertThreshold { get; set; } = 80m;
    [Column("is_active")]                    public bool     IsActive       { get; set; } = true;
    [Column("created_at")]                   public DateTime CreatedAt      { get; set; }
 
    public Category? Category { get; set; }
}
 
[Table("audit_logs", Schema = "dbo")]
public class AuditLog
{
    [Key, Column("audit_id")]                public long     AuditId    { get; set; }
    [Column("user_id")]                      public int?     UserId     { get; set; }
    [Column("action")]                       public string   Action     { get; set; } = null!;
    [Column("table_name")]                   public string   TableName  { get; set; } = null!;
    [Column("record_id")]                    public int?     RecordId   { get; set; }
    [Column("old_values")]                   public string?  OldValues  { get; set; }
    [Column("new_values")]                   public string?  NewValues  { get; set; }
    [Column("ip_address")]                   public string?  IpAddress  { get; set; }
    [Column("user_agent")]                   public string?  UserAgent  { get; set; }
    [Column("created_at")]                   public DateTime CreatedAt  { get; set; }
}
 
[Table("anomalies", Schema = "dbo")]
public class Anomaly
{
    [Key, Column("anomaly_id")]              public int      AnomalyId       { get; set; }
    [Column("user_id")]                      public int      UserId          { get; set; }
    [Column("transaction_id")]               public int?     TransactionId   { get; set; }
    [Column("category_id")]                  public int?     CategoryId      { get; set; }
    [Column("anomaly_type")]                 public string   AnomalyType     { get; set; } = null!;
    [Column("severity")]                     public string   Severity        { get; set; } = "MEDIUM";
    [Column("description")]                  public string?  Description     { get; set; }
    [Column("detected_at")]                  public DateTime DetectedAt      { get; set; }
    [Column("acknowledged_at")]              public DateTime? AcknowledgedAt { get; set; }
    [Column("is_false_positive")]            public bool     IsFalsePositive { get; set; }
}