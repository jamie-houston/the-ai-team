# Add Tests

Create integration tests for the API endpoints.

## Your Task

1. Set up WebApplicationFactory with test database:
   - **IMPORTANT**: Use the **same database provider** as production with an in-memory connection
   - For SQLite: Use `DataSource=:memory:` (keep connection open during test lifetime)
   - Do NOT mix providers (e.g., EF InMemory + SQLite causes "multiple providers" errors)
2. Ensure Program.cs has `public partial class Program { }` for test discoverability
3. Create test class for each controller
4. Add tests for:
   - Happy path (create, read, update, delete)
   - Not found cases (404)
   - Validation failures (400)
   - Any special endpoints (summary, filter, etc.)
5. Run `dotnet test` and ensure all pass
6. Commit: "test: add integration tests for [Resource] API"

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
