using Microsoft.EntityFrameworkCore;

namespace ArenaVault.API.Data;

public class ArenaVaultDbContext : DbContext
{
    public ArenaVaultDbContext(DbContextOptions<ArenaVaultDbContext> options)
        : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
    }
}
