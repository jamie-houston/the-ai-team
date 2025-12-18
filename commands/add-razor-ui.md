# Add Razor Pages UI to Existing API

Add a server-rendered Razor Pages frontend to an existing Web API project.

Use the Razor Pages agent defined in `.claude/agents/specialized/dotnet/razor.md` to:

1. Add Razor Pages services and middleware to Program.cs
2. Create the Pages folder structure (_Layout, _ViewImports, _ViewStart)
3. Build CRUD pages for the main entities in the PRD
4. Wire up pages to use the existing DbContext/services
5. Verify build succeeds and UI renders
6. Commit the changes

Focus area: $ARGUMENTS

If no focus specified, create pages for all main entities.

## When to Use
- You finished the API and want a simple UI
- Traditional form submissions are fine
- SEO matters or time is limited
- PRD specifies Razor Pages

## Note
This is a "nice to have" — only do this if API is complete and tested.
Choose `/add-blazor-ui` instead if you want rich interactivity.
