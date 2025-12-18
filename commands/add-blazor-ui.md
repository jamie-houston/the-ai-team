# Add Blazor UI to Existing API

Add an interactive Blazor frontend to an existing Web API project.

Use the Blazor agent defined in `.claude/agents/specialized/dotnet/blazor.md` to:

1. Add Blazor services and middleware to Program.cs
2. Create the Components folder structure (App.razor, Routes.razor, Layout)
3. Build CRUD pages for the main entities in the PRD
4. Wire up pages to call the existing API endpoints
5. Verify build succeeds and UI renders
6. Commit the changes

Focus area: $ARGUMENTS

If no focus specified, create pages for all main entities.

## When to Use
- You finished the API and want a rich, interactive UI
- Real-time updates or SPA-like experience needed
- Want to demonstrate full-stack C# skills

## Note
This is a "nice to have" — only do this if API is complete and tested.
Choose `/add-razor-ui` instead if you want simpler server-rendered pages.
