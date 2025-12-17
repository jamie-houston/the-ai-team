# Create Data Layer (EF Core)

Implement entity models and DbContext based on the PRD.

## Your Task

1. Create enum(s) if needed (e.g., Category, Status)
2. Create entity model class(es) in Models/
3. Create DbContext in Data/
   - **Always add**: `using Microsoft.EntityFrameworkCore;` at the top
4. Configure relationships and constraints in OnModelCreating
5. Register DbContext in Program.cs with provider switching:
   ```csharp
   var provider = builder.Configuration.GetValue<string>("DatabaseProvider") ?? "Sqlite";
   builder.Services.AddDbContext<AppDbContext>(options =>
   {
       if (provider == "SqlServer")
           options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"));
       else
           options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection"));
   });
   ```
6. Verify appsettings.json has connection string (should exist from scaffold)
7. Verify `dotnet build` succeeds
8. Commit: "feat: add [Entity] model and DbContext"

## Common Using Statements

Always include these in DbContext and data files:
```csharp
using Microsoft.EntityFrameworkCore;
using YourProject.Api.Models;
```

## IMPORTANT

After creating data layer:
1. List the entities and properties created
2. Show the DbContext configuration
3. Confirm build succeeded
4. **STOP and wait for user review**
5. Tell user: "Data layer complete. When ready, run `/webapi` to create endpoints"

Do NOT proceed to API endpoints automatically.

## Focus (optional)

$ARGUMENTS

If no focus provided, implement all entities from PRD.md.
