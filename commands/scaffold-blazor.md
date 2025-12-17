# Scaffold Blazor Web App

Create a Blazor web application structure based on the PRD.

## Your Task

1. Create solution folder structure:
   ```
   [ProjectName]/
   ├── src/[ProjectName].Web/
   └── tests/[ProjectName].Tests/
   ```
2. Run `dotnet new` commands:
   - `dotnet new sln -n [ProjectName]`
   - `dotnet new blazor -n [ProjectName].Web -o src/[ProjectName].Web` (Blazor Web App - .NET 8+)
   - `dotnet new xunit -n [ProjectName].Tests -o tests/[ProjectName].Tests`
3. Wire up solution and project references
4. Add packages if needed (EF Core, etc.)
5. Verify `dotnet build` succeeds
6. Verify `dotnet run --project src/[ProjectName].Web` launches
7. Commit: "chore: scaffold [ProjectName] Blazor web app"

## Blazor Render Modes (.NET 8+)
- **Static SSR** - Server renders HTML, no interactivity
- **Interactive Server** - SignalR connection for interactivity
- **Interactive WebAssembly** - Runs in browser via WASM
- **Interactive Auto** - Server first, then WASM

Default is Interactive Server for simplicity.

## IMPORTANT

After scaffolding:
1. Show what was created
2. Confirm build succeeded
3. Show the URL to access the app
4. **STOP and wait for user review**
5. Tell user: "Blazor app scaffold complete. Run `/efcore` for data layer, or start building components"

Do NOT proceed automatically.

## Project Name

$ARGUMENTS

If no name provided, derive from PRD.md or ask.
