# .NET Development Workflow Guide

Build complete .NET Web APIs from requirements to production-ready code using specialized AI agents and slash commands.

## Quick Start

```bash
# 1. Describe your requirements
/analyze-prd <file> or text("Build a task management API with users, projects, and tasks")

# 2. Review the PRD, then scaffold
/scaffold <projectName> ("TaskManager")

# 3. Create data layer
/efcore

# 3b. Seed sample data (if project includes JSON/CSV data files)
/load-data

# 4. Build API endpoints
/webapi

# 5. Build frontend (optional)
/add-blazor-ui
# or
/add-razor-ui

# 6. Add or update tests
/test

# 7. Review code and PRD requirements
/review
```

## The Workflow

### Phase 1: Requirements → PRD

**Command:** `/analyze-prd [requirements]`
**Agent:** `prd-analyst`

Takes rough requirements (verbal notes, emails, specs) and produces:
- Project overview with tech stack
- User stories with acceptance criteria
- Data model draft
- API endpoints draft
- Prioritized task checklist
- Clarifying questions

```bash
/analyze-prd "I need an inventory system. Products have names, SKUs,
quantities. Users can add/remove stock. Need low-stock alerts."
# or
/analyze-prd @requirements.txt
```

**Output:** `PRD.md` in project root

---

### Phase 2: Project Scaffold

**Command:** `/scaffold [ProjectName]`
**Agent:** `dotnet-scaffold-expert`

Creates the solution structure:
```
ProjectName/
├── src/
│   └── ProjectName.Api/
│       ├── Controllers/
│       ├── Models/
│       ├── Data/
│       └── Program.cs
├── tests/
│   └── ProjectName.Tests/
└── ProjectName.sln
```

**Packages installed:**
- EF Core (SQLite + SqlServer + Design)
- xUnit, FluentAssertions, Mvc.Testing
- JWT Bearer (if auth required)
- Swashbuckle for Swagger

---

### Phase 3: Data Layer

**Command:** `/efcore [entity-or-feature]`
**Agent:** `dotnet-efcore-expert`

Creates:
- Entity classes in `Models/`
- `AppDbContext` in `Data/`
- Fluent API configurations
- Initial migration

```bash
/efcore              # All entities from PRD
/efcore Product      # Just Product entity
```

**Key patterns:**
- Config-based provider switching (SQLite dev, SqlServer prod)
- Test-compatible seed data with environment check
- Avoids `HasDefaultValueSql()` for InMemory compatibility

---

### Phase 3b: Seed Sample Data (If Applicable)

**Command:** `/load-data`

Use this when your project includes sample data files (JSON, CSV) that need to be imported into the database.

```bash
/load-data              # Detects and imports data files
```

**What it does:**
- Copies data file into `Data/` folder (avoids fragile relative paths)
- Creates idempotent `DataSeeder.cs` (skips if data exists)
- Handles JSON/CSV parsing with enum mapping
- Adds startup seeding in Program.cs

**When to use:**
- PRD references a sample dataset file
- Requirements include demo/test data
- Need to import existing data from another system

**Skip this step** if your project doesn't include data files.

---

### Phase 4: API Endpoints

**Command:** `/webapi [entity-or-feature]`
**Agent:** `dotnet-webapi-expert`

Creates:
- DTOs for requests/responses
- Controllers with CRUD endpoints
- Problem Details for errors
- JWT auth configuration (if required)

```bash
/webapi              # All endpoints from PRD
/webapi Products     # Just Products controller
```

**Includes:**
- Proper status codes (201 Created, 204 No Content, 404 Not Found)
- Input validation
- Async/await patterns

---

### Phase 5: Frontend (Optional)

**Commands:** `/add-blazor-ui` or `/add-razor-ui`
**Agents:** `dotnet-blazor-expert` or `dotnet-razor-expert`

Add a web UI to your API:

```bash
/add-blazor-ui              # Interactive Blazor components
/add-blazor-ui admin        # Focus on admin pages
/add-razor-ui               # Traditional server-rendered pages
/add-razor-ui Products      # Just Products pages
```

**Blazor** - Best for:
- Interactive SPAs
- Real-time updates
- Component reuse

**Razor Pages** - Best for:
- Simple CRUD forms
- SEO-friendly content
- Traditional page navigation

---

### Phase 6: Testing

**Command:** `/test [controller-or-feature]`
**Agent:** `dotnet-testing-expert`

Creates:
- Unit tests for services
- Integration tests with `WebApplicationFactory`
- In-memory database isolation
- JWT token generation for auth tests

```bash
/test                # Tests for all endpoints
/test Products       # Just Products tests
```

**Key features:**
- Scans existing tests first (incremental)
- Per-test database isolation with `IAsyncLifetime`
- JWT config matching for auth tests

---

### Phase 7: Code Review

**Command:** `/review`
**Agent:** `dotnet-review-expert`

Reviews for:
- Async/await anti-patterns
- Missing null checks
- Security issues (SQL injection, auth gaps)
- EF Core query issues
- SOLID violations
- PRD requirement coverage

---

## Optional Commands

### Refactor Code

```bash
/refactor                  # Scan all controllers
/refactor ItemsController  # Specific controller
```

Applies SOLID principles:
- Extracts repository pattern from controllers
- Adds service layer for complex logic
- Configures dependency injection
- Splits fat classes

### Debug Issues

```bash
/debug "500 error on POST /api/items"
```

Systematic debugging:
- Reads error messages/stack traces
- Checks middleware order
- Validates DI registrations
- Tests in isolation

### SQL Optimization

```bash
/sql "GetOrdersWithItems query is slow"
```

- Analyzes LINQ queries
- Adds proper includes/projections
- Suggests indexes
- Rewrites N+1 problems

### Git Workflow

```bash
/git commit          # Clean commit with message
/git branch feature  # Create feature branch
```

### Verify Requirements

```bash
/verify              # Check all PRD requirements
```

Compares implementation against PRD acceptance criteria.

---

## Agents Reference

| Agent | Purpose |
|-------|---------|
| `dotnet-scaffold-expert` | Project structure and packages |
| `dotnet-efcore-expert` | Entity Framework Core setup |
| `dotnet-webapi-expert` | Controllers, DTOs, endpoints |
| `dotnet-testing-expert` | xUnit, integration tests |
| `dotnet-review-expert` | Code review, best practices |
| `dotnet-refactor-expert` | SOLID principles, DI |
| `dotnet-debug-expert` | Systematic debugging |
| `dotnet-sql-expert` | LINQ/SQL optimization |
| `dotnet-blazor-expert` | Blazor UI components |
| `dotnet-razor-expert` | Razor Pages UI |
| `dotnet-console-expert` | Console applications |

---

## Example: Complete API Build

```bash
# Start with requirements (inline text or file)
/analyze-prd "Build a bookstore API. Books have title, author, ISBN, price.
Users can browse, search, add to cart, checkout. Need user accounts."
# or: /analyze-prd @bookstore-requirements.txt

# Review PRD.md, then scaffold
/scaffold Bookstore

# Create entities: Book, User, Cart, Order, OrderItem
/efcore

# If you have sample data files (e.g., books.json, catalog.csv):
# /load-data

# Create all endpoints
/webapi

# Add admin UI for managing books/orders (optional)
/add-blazor-ui admin dashboard

# Add or update tests
/test

# Final review (checks code quality AND PRD requirements)
/review

# Commit
/git commit
```

---

## Tips

1. **Always review PRD** before scaffolding - catch issues early
2. **Run tests incrementally** - `/test` only adds new tests, won't duplicate
3. **Use `/refactor`** after initial implementation if controllers get fat
4. **Check `/verify`** before marking features complete
5. **Each command stops and waits** - no runaway automation

---

## Workflow Diagram

```
┌─────────────────┐
│  Requirements   │
└────────┬────────┘
         │ /analyze-prd
         ▼
┌─────────────────┐
│     PRD.md      │◄─── Review & Approve
└────────┬────────┘
         │ /scaffold
         ▼
┌─────────────────┐
│ Project Structure│
└────────┬────────┘
         │ /efcore
         ▼
┌─────────────────┐
│   Data Layer    │
└────────┬────────┘
         │ /load-data (if sample data files exist)
         ▼
┌─────────────────┐
│   Seed Data     │ (optional)
└────────┬────────┘
         │ /webapi
         ▼
┌─────────────────┐
│  API Endpoints  │
└────────┬────────┘
         │ /add-blazor-ui or /add-razor-ui (optional)
         ▼
┌─────────────────┐
│    Frontend     │ (optional)
└────────┬────────┘
         │ /test
         ▼
┌─────────────────┐
│     Tests       │
└────────┬────────┘
         │ /review
         ▼
┌─────────────────┐
│  Code Review    │
└────────┬────────┘
         │ /verify (optional)
         ▼
┌─────────────────┐
│   Production    │
│     Ready!      │
└─────────────────┘
```
