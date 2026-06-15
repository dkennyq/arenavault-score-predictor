using Microsoft.EntityFrameworkCore;
using ArenaVault.API.Data;
using ArenaVault.API.Models;

var builder = WebApplication.CreateBuilder(args);

// Configure Kestrel to use PORT environment variable (Railway compatibility)
var port = Environment.GetEnvironmentVariable("PORT") ?? "5000";
builder.WebHost.UseUrls($"http://0.0.0.0:{port}");

// Build connection string with Railway compatibility
string connectionString;

// First, try to get from configuration (works for both Railway env vars and appsettings.json)
var configConnectionString = builder.Configuration.GetConnectionString("DefaultConnection");

if (!string.IsNullOrEmpty(configConnectionString) && configConnectionString.StartsWith("postgresql://"))
{
    // Railway PostgreSQL URI format: postgresql://user:password@host:port/database
    // Convert to Npgsql connection string format
    try
    {
        var uri = new Uri(configConnectionString);
        var password = uri.UserInfo.Split(':').Length > 1 ? uri.UserInfo.Split(':')[1] : "";
        connectionString = $"Host={uri.Host};" +
                          $"Port={uri.Port};" +
                          $"Database={uri.AbsolutePath.TrimStart('/')};" +
                          $"Username={uri.UserInfo.Split(':')[0]};" +
                          $"Password={password};" +
                          $"SSL Mode=Prefer;" +
                          $"Trust Server Certificate=true";
        
        Console.WriteLine($"Using Railway PostgreSQL connection: {uri.Host}:{uri.Port}/{uri.AbsolutePath.TrimStart('/')}");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Error parsing PostgreSQL URI: {ex.Message}");
        throw;
    }
}
else if (!string.IsNullOrEmpty(configConnectionString))
{
    // Already in Npgsql format (from appsettings.json for local development)
    connectionString = configConnectionString;
    Console.WriteLine("Using local PostgreSQL connection from appsettings.json");
}
else
{
    throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
}

// Add services to the container
builder.Services.AddDbContext<ArenaVaultDbContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors();

// Health check endpoint
app.MapGet("/api/health", () =>
{
    return Results.Ok(new HealthResponse
    {
        Status = "Healthy",
        Message = "Backend API is running",
        Timestamp = DateTime.UtcNow
    });
})
.WithName("HealthCheck");

// Database connectivity check endpoint
app.MapGet("/api/health/database", async (ArenaVaultDbContext context) =>
{
    try
    {
        await context.Database.CanConnectAsync();
        
        // Ensure database is created
        await context.Database.EnsureCreatedAsync();
        
        return Results.Ok(new HealthResponse
        {
            Status = "Connected",
            Message = "Database connection successful! ✓",
            Timestamp = DateTime.UtcNow
        });
    }
    catch (Exception ex)
    {
        return Results.Ok(new HealthResponse
        {
            Status = "Error",
            Message = $"Database connection failed: {ex.Message}",
            Timestamp = DateTime.UtcNow
        });
    }
})
.WithName("DatabaseHealthCheck");

app.Run();
