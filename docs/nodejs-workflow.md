# Node.js Development Workflow Guide

Build complete Node.js APIs from requirements to production-ready code using specialized AI agents and slash commands.

## Quick Start

```bash
# 1. Describe your requirements
/analyze-prd <file> or text("Build a task management API with users, projects, and tasks")

# 2. Review the PRD, then scaffold
/scaffold-nodejs <projectName> ("TaskManager")

# 3. Create data layer
/nodejs-db

# 4. Build API endpoints
/nodejs-api

# 5. Add tests
/nodejs-test

# 6. Review code
/nodejs-review
```

## The Workflow

### Phase 1: Requirements → PRD

**Command:** `/analyze-prd [requirements]`
**Agent:** `prd-analyst`

Takes rough requirements and produces:
- Project overview with tech stack
- User stories with acceptance criteria
- Data model draft
- API endpoints draft
- Prioritized task checklist

```bash
/analyze-prd "I need an inventory system. Products have names, SKUs,
quantities. Users can add/remove stock. Need low-stock alerts."
# or
/analyze-prd @requirements.txt
```

**Output:** `PRD.md` in project root

---

### Phase 2: Project Scaffold

**Command:** `/scaffold-nodejs [ProjectName]`
**Agent:** `nodejs-scaffold-expert`

Creates the project structure:
```
project-name/
├── src/
│   ├── routes/
│   ├── models/
│   ├── services/
│   ├── middleware/
│   ├── utils/
│   ├── types/
│   └── index.ts
├── tests/
│   ├── integration/
│   └── unit/
├── prisma/
│   └── schema.prisma
├── package.json
├── tsconfig.json
├── vitest.config.ts
└── .env.example
```

**Packages installed:**
- TypeScript with strict mode
- Express, Fastify, or Hono (your choice)
- Prisma for database
- Zod for validation
- Vitest for testing
- ESLint + Prettier

---

### Phase 3: Data Layer

**Command:** `/nodejs-db [entity-or-feature]`
**Agent:** `nodejs-database-expert`

Creates:
- Prisma schema in `prisma/schema.prisma`
- Database client singleton in `src/lib/prisma.ts`
- Repository pattern (optional)
- Migrations

```bash
/nodejs-db              # All entities from PRD
/nodejs-db Product      # Just Product entity
```

**Key patterns:**
- TypeScript-first with Prisma
- Soft deletes via middleware
- Proper indexes for queries
- Relationship definitions

---

### Phase 4: API Endpoints

**Command:** `/nodejs-api [entity-or-feature]`
**Agent:** `nodejs-api-expert`

Creates:
- Route handlers with Express/Fastify
- Zod validation schemas
- Auth middleware (JWT)
- Error handling middleware
- Request/response types

```bash
/nodejs-api              # All endpoints from PRD
/nodejs-api Products     # Just Products routes
```

**Includes:**
- Proper status codes
- Consistent JSON responses
- Input validation
- Async/await patterns

---

### Phase 5: Testing

**Command:** `/nodejs-test [service-or-route]`
**Agent:** `nodejs-testing-expert`

Creates:
- Unit tests with Vitest
- Integration tests with Supertest
- Test database setup
- Mock utilities

```bash
/nodejs-test             # Tests for all functionality
/nodejs-test users       # Just user tests
```

**Key features:**
- Per-test database isolation
- JWT token generation for auth tests
- Proper async handling

---

### Phase 6: Code Review

**Command:** `/nodejs-review`
**Agent:** `nodejs-review-expert`

Reviews for:
- TypeScript strict compliance
- Async/await anti-patterns
- Security issues
- Error handling gaps
- API design best practices

---

## Optional Commands

### Debug Issues

```bash
/nodejs-debug "500 error on POST /api/users"
```

Systematic debugging:
- Reads error messages/stack traces
- Checks middleware order
- Validates async patterns
- Tests in isolation

---

## Agents Reference

| Agent | Purpose |
|-------|---------|
| `nodejs-scaffold-expert` | Project structure and packages |
| `nodejs-database-expert` | Prisma schema and data access |
| `nodejs-api-expert` | Routes, middleware, validation |
| `nodejs-testing-expert` | Vitest, integration tests |
| `nodejs-review-expert` | Code review, best practices |
| `nodejs-debug-expert` | Systematic debugging |

---

## Example: Complete API Build

```bash
# Start with requirements
/analyze-prd "Build a bookstore API. Books have title, author, ISBN, price.
Users can browse, search, add to cart, checkout. Need user accounts."

# Review PRD.md, then scaffold
/scaffold-nodejs Bookstore

# Create entities: Book, User, Cart, Order
/nodejs-db

# Create all endpoints
/nodejs-api

# Add tests
/nodejs-test

# Final review
/nodejs-review

# Commit
/git commit
```

---

## Tips

1. **Always review PRD** before scaffolding - catch issues early
2. **Run tests incrementally** - `/nodejs-test` only adds new tests
3. **Use TypeScript strict mode** - it's enabled by default
4. **Check `/nodejs-review`** before marking features complete
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
         │ /scaffold-nodejs
         ▼
┌─────────────────┐
│ Project Structure│
└────────┬────────┘
         │ /nodejs-db
         ▼
┌─────────────────┐
│   Data Layer    │
└────────┬────────┘
         │ /nodejs-api
         ▼
┌─────────────────┐
│  API Endpoints  │
└────────┬────────┘
         │ /nodejs-test
         ▼
┌─────────────────┐
│     Tests       │
└────────┬────────┘
         │ /nodejs-review
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
