# Scaffold Console App

Create a .NET console application structure based on the PRD.

## Your Task

1. Create solution folder structure:
   ```
   [ProjectName]/
   ├── src/[ProjectName]/
   └── tests/[ProjectName].Tests/
   ```
2. Run `dotnet new` commands:
   - `dotnet new sln -n [ProjectName]`
   - `dotnet new console -n [ProjectName] -o src/[ProjectName]`
   - `dotnet new xunit -n [ProjectName].Tests -o tests/[ProjectName].Tests`
3. Wire up solution and project references
4. Add any needed packages (e.g., System.CommandLine for CLI args)
5. Verify `dotnet build` succeeds
6. Verify `dotnet run --project src/[ProjectName]` works
7. Commit: "chore: scaffold [ProjectName] console app"

## IMPORTANT

After scaffolding:
1. Show what was created
2. Confirm build and run succeeded
3. **STOP and wait for user review**
4. Tell user: "Console app scaffold complete. Run `/efcore` if you need data access, or start implementing in Program.cs"

Do NOT proceed automatically.

## Project Name

$ARGUMENTS

If no name provided, derive from PRD.md or ask.
