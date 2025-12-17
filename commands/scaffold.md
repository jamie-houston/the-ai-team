# Scaffold Project

Create the .NET solution structure based on the PRD.

## Your Task

1. Create solution folder structure:
   ```
   [ProjectName]/
   ├── src/[ProjectName].Api/
   └── tests/[ProjectName].Tests/
   ```
2. Run `dotnet new` commands (sln, webapi, xunit)
3. **Remove template files**: Delete WeatherForecast.cs and WeatherForecastController.cs
4. Add package references (EF Core, test libraries)
5. Wire up project references
6. Configure appsettings.json with connection string
7. Verify `dotnet build` succeeds
8. Commit: "chore: scaffold [ProjectName] solution"

## IMPORTANT

After scaffolding:
1. Show what was created (folder structure, packages added)
2. Confirm build succeeded
3. **STOP and wait for user review**
4. Tell user: "Scaffold complete. When ready, run `/efcore` to create the data layer"

Do NOT proceed to data layer automatically.

## Project Name

$ARGUMENTS

If no name provided, derive from PRD.md or ask.
