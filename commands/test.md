---
description: Create integration tests for API endpoints
argument-hint: [controller-or-feature]
---

# Add Tests

Create integration tests for the API endpoints.

## Your Task

1. Set up a custom WebApplicationFactory with proper configuration:
   ```csharp
   public class CustomWebApplicationFactory : WebApplicationFactory<Program>
   {
       public string DatabaseName { get; set; } = Guid.NewGuid().ToString();

       protected override void ConfigureWebHost(IWebHostBuilder builder)
       {
           // CRITICAL: If using JWT auth, configure with SAME values as Program.cs defaults
           // Token generation (JwtService) uses IConfiguration at runtime
           // Token validation uses values captured at startup
           // Mismatched issuer/audience = all authenticated requests fail
           builder.ConfigureAppConfiguration((context, config) =>
           {
               config.AddInMemoryCollection(new Dictionary<string, string?>
               {
                   // Match these to your Program.cs default values exactly!
                   ["Jwt:Key"] = "YourDefaultKeyFromProgramCs",
                   ["Jwt:Issuer"] = "YourAppName",
                   ["Jwt:Audience"] = "YourAppName"
               });
           });

           builder.ConfigureServices(services =>
           {
               // Remove ALL EF-related services to avoid provider conflicts
               // Just removing DbContextOptions is NOT enough - SQLite and InMemory will conflict
               var descriptorsToRemove = services.Where(d =>
                   d.ServiceType == typeof(DbContextOptions<AppDbContext>) ||
                   d.ServiceType == typeof(AppDbContext) ||
                   d.ServiceType.FullName?.Contains("EntityFrameworkCore") == true).ToList();

               foreach (var descriptor in descriptorsToRemove)
                   services.Remove(descriptor);

               // Add in-memory database with unique name
               services.AddDbContext<AppDbContext>(options =>
                   options.UseInMemoryDatabase(DatabaseName));
           });
       }
   }
   ```

2. Use `IAsyncLifetime` for per-test isolation:
   ```csharp
   public abstract class IntegrationTestBase : IAsyncLifetime
   {
       protected CustomWebApplicationFactory Factory { get; private set; } = null!;
       protected HttpClient Client { get; private set; } = null!;

       public Task InitializeAsync()
       {
           Factory = new CustomWebApplicationFactory { DatabaseName = Guid.NewGuid().ToString() };
           Client = Factory.CreateClient();
           return Task.CompletedTask;
       }

       public async Task DisposeAsync()
       {
           Client.Dispose();
           await Factory.DisposeAsync();
       }

       // Seed data through Factory's service provider - NOT a separate DbContext
       protected async Task SeedData<T>(T entity) where T : class
       {
           using var scope = Factory.Services.CreateScope();
           var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
           context.Set<T>().Add(entity);
           await context.SaveChangesAsync();
       }
   }
   ```

3. **Handle seed data in DbContext** (pick one approach):

   **Option A - Environment variable check** (recommended):
   Add to DbContext.OnModelCreating:
   ```csharp
   // Skip seeding during tests
   if (Environment.GetEnvironmentVariable("SKIP_DB_SEED") != "true")
   {
       SeedData(modelBuilder);
   }
   ```

   **Option B - UseContentRoot** (has side effects):
   ```csharp
   builder.UseContentRoot(Path.GetTempPath());
   ```
   Note: This prevents appsettings.json loading, which may break JWT config.

   **Also**: Remove any `HasDefaultValueSql("CURRENT_TIMESTAMP")` calls - InMemory doesn't support SQL functions.

4. Ensure Program.cs has `public partial class Program { }` for test discoverability

5. Create test class for each controller

6. Add tests for:
   - Happy path (create, read, update, delete)
   - Authentication (with token, without token)
   - Authorization (correct role, wrong role)
   - Not found cases (404)
   - Validation failures (400)
   - Any special endpoints (summary, filter, etc.)

7. Run `dotnet test` and ensure all pass

8. Commit: "test: add integration tests for [Resource] API"

## Common Pitfalls

- **JWT Mismatch**: If tokens aren't working, check that test config matches Program.cs defaults for Jwt:Key, Jwt:Issuer, Jwt:Audience
- **Provider Conflict**: "Services for database providers X, Y have been registered" - remove ALL EF services, not just DbContextOptions
- **Seed Data Conflicts**: Tests fail with 500 errors on login - seed data is loading and conflicting with test data
- **Empty JSON Error**: "The input does not contain any JSON tokens" - the response is likely 401/403, not JSON

## IMPORTANT

After creating tests:
1. List the tests created
2. Show test results (passed/failed count)
3. **STOP and wait for user review**
4. Tell user: "Tests complete. Run `/review` for final code review, or `/git commit` to finalize"

Do NOT proceed automatically.

## Focus (optional)

$ARGUMENTS

If no focus provided, add tests for all implemented endpoints.
