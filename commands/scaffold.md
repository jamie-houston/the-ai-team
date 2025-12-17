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
   - **Note**: `dotnet new webapi -o src/ProjectName.Api` may create `src/ProjectName.Api/src/ProjectName.Api/`. Check and flatten if needed.
3. **Remove template files**: Delete WeatherForecast.cs and WeatherForecastController.cs
4. Add package references with **explicit version 9.0.0** (NuGet may grab 10.x which is incompatible with .NET 9):
   ```bash
   # API project
   dotnet add package Microsoft.EntityFrameworkCore.Sqlite --version 9.0.0
   dotnet add package Microsoft.EntityFrameworkCore.Design --version 9.0.0

   # Test project
   dotnet add package Microsoft.AspNetCore.Mvc.Testing --version 9.0.0
   dotnet add package Microsoft.EntityFrameworkCore.InMemory --version 9.0.0
   ```
5. Wire up project references
6. Configure appsettings.json with connection string
7. **Add test entry point**: Append `public partial class Program { }` to Program.cs for WebApplicationFactory discoverability
8. Verify `dotnet build` succeeds
9. Commit: "chore: scaffold [ProjectName] solution"

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
