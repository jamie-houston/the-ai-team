# Add Tests

Create integration tests for the API endpoints.

## Your Task

1. Set up WebApplicationFactory with in-memory database:
   ```csharp
   private HttpClient CreateClient(string dbName)
   {
       return _factory.WithWebHostBuilder(builder =>
       {
           // IMPORTANT: Prevent seed data from loading in tests
           builder.UseContentRoot(Path.GetTempPath());

           builder.ConfigureServices(services =>
           {
               // Remove all EF-related services
               var efServices = services.Where(d =>
                   d.ServiceType.FullName?.Contains("EntityFrameworkCore") == true ||
                   d.ServiceType == typeof(AppDbContext) ||
                   d.ServiceType == typeof(DbContextOptions<AppDbContext>)).ToList();

               foreach (var service in efServices)
                   services.Remove(service);

               // Add in-memory database with unique name per test
               services.AddDbContext<AppDbContext>(options =>
                   options.UseInMemoryDatabase(dbName));
           });
       }).CreateClient();
   }
   ```

2. **Key patterns**:
   - Use unique DB name per test to avoid pollution
   - `UseContentRoot(Path.GetTempPath())` prevents seed data loading
   - Each test creates its own data - don't rely on seed data

3. Ensure Program.cs has `public partial class Program { }` for test discoverability

4. Create test class for each controller

5. Add tests for:
   - Happy path (create, read, update, delete)
   - Not found cases (404)
   - Validation failures (400)
   - Any special endpoints (summary, filter, etc.)

6. Run `dotnet test` and ensure all pass

7. Commit: "test: add integration tests for [Resource] API"

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
