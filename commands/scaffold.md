---
description: Create .NET Web API solution with EF Core and xUnit
argument-hint: [project-name]
---

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
   # API project - both providers for dev/prod flexibility
   dotnet add package Microsoft.EntityFrameworkCore.Sqlite --version 9.0.0
   dotnet add package Microsoft.EntityFrameworkCore.SqlServer --version 9.0.0
   dotnet add package Microsoft.EntityFrameworkCore.Design --version 9.0.0

   # Test project
   dotnet add package Microsoft.AspNetCore.Mvc.Testing --version 9.0.0
   dotnet add package Microsoft.EntityFrameworkCore.InMemory --version 9.0.0
   ```

   **For JWT authentication** (if needed later):
   ```bash
   dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer --version 9.0.0
   dotnet add package BCrypt.Net-Next  # For password hashing
   ```

   **For Swagger** (avoid 10.x namespace issues):
   ```bash
   dotnet add package Swashbuckle.AspNetCore --version 6.5.0
   ```
5. Wire up project references
6. Configure appsettings.json with connection string and provider setting:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Data Source=app.db"
     },
     "DatabaseProvider": "Sqlite"
   }
   ```
   Note: For production SQL Server, change to:
   ```json
   {
     "DatabaseProvider": "SqlServer",
     "ConnectionStrings": {
       "DefaultConnection": "Server=...;Database=...;Trusted_Connection=true;"
     }
   }
   ```
7. Create `.editorconfig` in solution root for consistent code style:
   ```ini
   root = true

   [*.cs]
   indent_style = space
   indent_size = 4
   charset = utf-8

   # Naming conventions
   dotnet_naming_style.pascal_case.capitalization = pascal_case
   dotnet_naming_style.camel_case.capitalization = camel_case

   # PascalCase for classes, methods, properties
   dotnet_naming_rule.types_pascal.symbols = types
   dotnet_naming_rule.types_pascal.style = pascal_case
   dotnet_naming_rule.types_pascal.severity = warning
   dotnet_naming_symbols.types.applicable_kinds = class, struct, interface, enum, method, property

   # camelCase for locals and parameters
   dotnet_naming_rule.locals_camel.symbols = locals
   dotnet_naming_rule.locals_camel.style = camel_case
   dotnet_naming_rule.locals_camel.severity = warning
   dotnet_naming_symbols.locals.applicable_kinds = parameter, local

   # Prefer 'is null' over '== null'
   dotnet_style_prefer_is_null_check_over_reference_equality_method = true:warning

   # Use explicit types for built-in types
   csharp_style_var_for_built_in_types = false:suggestion
   ```
8. **Add test entry point**: Append `public partial class Program { }` to Program.cs for WebApplicationFactory discoverability
9. Verify `dotnet build` succeeds
10. Commit: "chore: scaffold [ProjectName] solution"

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
