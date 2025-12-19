# Add Blazor UI to Existing API

Add an interactive Blazor frontend to an existing Web API project.

Use the Blazor agent defined in `.claude/agents/specialized/dotnet/blazor.md` to:

1. Add Blazor services and middleware to Program.cs
2. Ensure database initialization (`EnsureCreated()`) is called on startup
3. Create the Components folder structure (App.razor, Routes.razor, Layout)
4. Build CRUD components for the main entities in the PRD
5. Wire up components to call the existing API endpoints
6. Run `dotnet build` and verify no errors
7. Run `dotnet test` and verify all tests pass
8. **Start the app and verify pages load** (smoke test key endpoints)
9. Commit the changes

Focus area: $ARGUMENTS

If no focus specified, create pages for all main entities.

## Smoke Test Checklist

Before committing, verify the app actually works:
```bash
# Start the app
dotnet run --urls "http://localhost:5000" &
sleep 8

# Test key pages return 200
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/        # Home
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/events  # API

# Stop the app
pkill -f "dotnet.*run"
```

## Common Issues

- **Missing database**: Add `context.Database.EnsureCreated()` in Program.cs after `builder.Build()`
- **Test conflicts with seed data**: Set `SKIP_DB_SEED=true` in test setup
- **HttpClient not configured**: Register `builder.Services.AddHttpClient()` for API calls

## When to Use
- You finished the API and want a rich, interactive UI
- Real-time updates or SPA-like experience needed
- Want to demonstrate full-stack C# skills

## Note
This is a "nice to have" — only do this if API is complete and tested.
Choose `/add-razor-ui` instead if you want simpler server-rendered pages.
