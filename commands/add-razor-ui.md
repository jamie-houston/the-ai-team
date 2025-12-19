---
description: Add Razor Pages UI to existing Web API project
argument-hint: [entity-focus]
---

# Add Razor Pages UI to Existing API

Add a server-rendered Razor Pages frontend to an existing Web API project.

Use the Razor Pages agent defined in `.claude/agents/specialized/dotnet/razor.md` to:

1. Add Razor Pages services and middleware to Program.cs
2. Ensure database initialization (`EnsureCreated()`) is called on startup
3. Create the Pages folder structure (_Layout, _ViewImports, _ViewStart)
4. Build CRUD pages for the main entities in the PRD
5. Wire up pages to use the existing DbContext/services
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
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/Events  # List
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/Account/Login  # Auth

# Stop the app
pkill -f "dotnet.*run"
```

## Common Issues

- **Missing database**: Add `context.Database.EnsureCreated()` in Program.cs after `builder.Build()`
- **Test conflicts with seed data**: Set `SKIP_DB_SEED=true` in test setup
- **Cookie auth not working**: Need dual auth scheme (Cookies for pages, JWT for API)

## When to Use
- You finished the API and want a simple UI
- Traditional form submissions are fine
- SEO matters or time is limited
- PRD specifies Razor Pages

## Note
This is a "nice to have" — only do this if API is complete and tested.
Choose `/add-blazor-ui` instead if you want rich interactivity.
