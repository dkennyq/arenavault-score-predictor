using Microsoft.EntityFrameworkCore;
using ArenaVault.API.Data;
using ArenaVault.API.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddDbContext<ArenaVaultDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

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
