# Generate README

Create comprehensive project documentation based on the codebase.

## Your Task

1. Read PRD.md (if exists) for project description
2. Scan the project structure to understand what was built
3. Generate a README.md with the following sections:

```markdown
# [Project Name]

[Brief description from PRD or inferred from code]

## Prerequisites

- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [SQLite](https://www.sqlite.org/) (default) or SQL Server

## Getting Started

### Clone and Setup
```bash
git clone [repo-url]
cd [project-name]
```

### Configure Database
Default uses SQLite. For SQL Server, update `appsettings.json`:
```json
{
  "DatabaseProvider": "SqlServer",
  "ConnectionStrings": {
    "DefaultConnection": "Server=...;Database=...;Trusted_Connection=true;"
  }
}
```

### Build and Run
```bash
dotnet restore
dotnet build
dotnet run --project src/[ProjectName].Api
```

The API will be available at `https://localhost:5001` (or `http://localhost:5000`).

### Swagger UI
Navigate to `https://localhost:5001/swagger` to explore the API.

## Running Tests
```bash
dotnet test
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/[resource]` | Get all items |
| GET | `/api/[resource]/{id}` | Get item by ID |
| POST | `/api/[resource]` | Create new item |
| PUT | `/api/[resource]/{id}` | Update item |
| DELETE | `/api/[resource]/{id}` | Delete item |

## Project Structure
```
[ProjectName]/
├── src/[ProjectName].Api/
│   ├── Controllers/     # API endpoints
│   ├── Models/          # Entity models and DTOs
│   ├── Data/            # DbContext and migrations
│   ├── Services/        # Business logic (if any)
│   └── Program.cs       # App configuration
├── tests/[ProjectName].Tests/
│   └── ...              # Unit and integration tests
└── [ProjectName].sln
```

## Configuration

| Setting | Description | Default |
|---------|-------------|---------|
| `DatabaseProvider` | `Sqlite` or `SqlServer` | `Sqlite` |
| `ConnectionStrings:DefaultConnection` | Database connection string | `Data Source=app.db` |

## Development Notes

- [Any important notes about the implementation]
- [Trade-offs made]
- [Known limitations]
```

4. Fill in actual values by scanning:
   - Controllers/ for API endpoints
   - Models/ for entities
   - PRD.md for requirements
   - Project structure for folder layout

5. Commit: "docs: add README with setup instructions"

## IMPORTANT

After generating README:
1. Show the user the generated README
2. Ask if they want any sections expanded or modified
3. **STOP and wait for user review**
4. Tell user: "README complete. Run `/review` for final code review"

Do NOT proceed to review automatically.

## Focus (optional)

$ARGUMENTS

If arguments provided, focus on specific sections (e.g., "api" for detailed API docs).
