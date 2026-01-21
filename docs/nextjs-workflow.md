# Next.js Development Workflow Guide

Build complete Next.js applications from requirements to production-ready code using specialized AI agents and slash commands.

## Quick Start

```bash
# 1. Describe your requirements
/analyze-prd <file> or text("Build a blog platform with posts, comments, and user profiles")

# 2. Review the PRD, then scaffold
/scaffold-nextjs <projectName> ("BlogApp")

# 3. Set up authentication (if needed)
/nextjs-auth

# 4. Create data layer
/nextjs-db

# 5. Build API routes (optional for external API)
/nextjs-api

# 6. Create pages and components
/nextjs-pages

# 7. Add tests
/nextjs-test

# 8. Review code
/nextjs-review
```

## The Workflow

### Phase 1: Requirements → PRD

**Command:** `/analyze-prd [requirements]`
**Agent:** `prd-analyst`

Takes rough requirements and produces:
- Project overview with tech stack
- User stories with acceptance criteria
- Data model draft
- Page structure draft
- Prioritized task checklist

```bash
/analyze-prd "I need a SaaS dashboard. Users sign up, create projects,
invite team members, track metrics. Need OAuth login."
# or
/analyze-prd @requirements.txt
```

**Output:** `PRD.md` in project root

---

### Phase 2: Project Scaffold

**Command:** `/scaffold-nextjs [ProjectName]`
**Agent:** `nextjs-scaffold-expert`

Creates a modern Next.js 15 project:
```
project-name/
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── api/
│   ├── components/
│   │   └── ui/
│   ├── lib/
│   └── types/
├── tests/
├── prisma/
├── public/
├── package.json
├── tsconfig.json
├── tailwind.config.ts
└── vitest.config.ts
```

**Packages installed:**
- Next.js 15 with App Router
- TypeScript strict mode
- Tailwind CSS
- Prisma for database
- Zod for validation
- Vitest + Testing Library

---

### Phase 3: Authentication (Optional)

**Command:** `/nextjs-auth [providers]`
**Agent:** `nextjs-auth-expert`

Sets up NextAuth.js v5:
- OAuth providers (GitHub, Google)
- Credentials authentication
- Session management
- Protected route middleware
- Auth Server Actions

```bash
/nextjs-auth                    # Default: GitHub + credentials
/nextjs-auth GitHub Google      # Multiple OAuth providers
```

**Includes:**
- Login/Register pages
- User menu component
- Role-based access control
- JWT session strategy

---

### Phase 4: Data Layer

**Command:** `/nextjs-db [entity-or-feature]`
**Agent:** `nextjs-database-expert`

Creates:
- Prisma schema with relations
- Cached data access functions (unstable_cache)
- Server Actions for mutations
- Proper cache invalidation (revalidateTag)

```bash
/nextjs-db              # All entities from PRD
/nextjs-db Post         # Just Post entity
```

**Key patterns:**
- Server-side data fetching
- Cache tags for revalidation
- Server Actions for mutations
- Type-safe Prisma queries

---

### Phase 5: API Routes (Optional)

**Command:** `/nextjs-api [entity-or-feature]`
**Agent:** `nextjs-api-expert`

Creates Route Handlers:
- RESTful endpoints in `app/api/`
- Zod validation
- Consistent error responses
- Auth middleware

```bash
/nextjs-api              # All endpoints from PRD
/nextjs-api users        # Just users API
```

**When to use:**
- External API consumers
- Mobile app backends
- Third-party integrations

**Skip if:** Using Server Actions for all mutations

---

### Phase 6: Pages & Components

**Command:** `/nextjs-pages [page-or-feature]`
**Agent:** `nextjs-pages-expert`

Creates:
- Server Components (default)
- Client Components (when needed)
- Layouts with auth checks
- Forms with Server Actions
- Loading and error states

```bash
/nextjs-pages            # All pages from PRD
/nextjs-pages dashboard  # Just dashboard pages
```

**Includes:**
- Suspense boundaries
- Skeleton loading states
- Error boundaries
- Responsive Tailwind styling

---

### Phase 7: Testing

**Command:** `/nextjs-test [component-or-feature]`
**Agent:** `nextjs-testing-expert`

Creates:
- Component tests with Vitest + Testing Library
- Server Action tests
- API route tests
- E2E tests with Playwright

```bash
/nextjs-test             # Tests for all functionality
/nextjs-test auth        # Just auth tests
```

**Key features:**
- Proper mocking of Next.js features
- Server Action testing patterns
- E2E user flow tests

---

### Phase 8: Code Review

**Command:** `/nextjs-review`
**Agent:** `nextjs-review-expert`

Reviews for:
- Server vs Client Component usage
- Data fetching patterns
- Cache invalidation
- Security issues
- Accessibility
- Performance

---

## Agents Reference

| Agent | Purpose |
|-------|---------|
| `nextjs-scaffold-expert` | Project structure with App Router |
| `nextjs-auth-expert` | NextAuth.js setup |
| `nextjs-database-expert` | Prisma + data access + Server Actions |
| `nextjs-api-expert` | Route Handlers |
| `nextjs-pages-expert` | Pages, components, layouts |
| `nextjs-testing-expert` | Vitest, Testing Library, Playwright |
| `nextjs-review-expert` | Code review, best practices |

---

## Example: Complete App Build

```bash
# Start with requirements
/analyze-prd "Build a project management tool. Users create projects,
add tasks, assign team members, track progress. Need OAuth login."

# Review PRD.md, then scaffold
/scaffold-nextjs ProjectHub

# Set up authentication
/nextjs-auth GitHub Google

# Create data layer with Server Actions
/nextjs-db

# Create pages and components
/nextjs-pages

# Add tests
/nextjs-test

# Final review
/nextjs-review

# Commit
/git commit
```

---

## Server Components vs Client Components

**Use Server Components (default) for:**
- Data fetching
- Database access
- Accessing backend resources
- Large dependencies
- SEO-critical content

**Use Client Components ('use client') for:**
- Interactivity (onClick, onChange)
- useState, useEffect hooks
- Browser APIs
- Event listeners

```
┌─────────────────────────────────────┐
│         Server Component            │
│  ┌───────────────────────────────┐  │
│  │    Fetches data from DB       │  │
│  │    Passes to client component │  │
│  │    ┌───────────────────────┐  │  │
│  │    │   Client Component    │  │  │
│  │    │   Handles clicks      │  │  │
│  │    │   Manages local state │  │  │
│  │    └───────────────────────┘  │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## Tips

1. **Server Components by default** - only add 'use client' when needed
2. **Use Server Actions for mutations** - no need for API routes for internal mutations
3. **Cache with tags** - always add tags to unstable_cache for proper revalidation
4. **Suspense for loading** - wrap async components in Suspense
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
         │ /scaffold-nextjs
         ▼
┌─────────────────┐
│ Project Structure│
└────────┬────────┘
         │ /nextjs-auth (optional)
         ▼
┌─────────────────┐
│ Authentication  │
└────────┬────────┘
         │ /nextjs-db
         ▼
┌─────────────────┐
│   Data Layer    │
│ + Server Actions│
└────────┬────────┘
         │ /nextjs-api (optional)
         ▼
┌─────────────────┐
│  Route Handlers │ (for external API)
└────────┬────────┘
         │ /nextjs-pages
         ▼
┌─────────────────┐
│ Pages & UI      │
└────────┬────────┘
         │ /nextjs-test
         ▼
┌─────────────────┐
│     Tests       │
└────────┬────────┘
         │ /nextjs-review
         ▼
┌─────────────────┐
│  Code Review    │
└────────┬────────┘
         │ Deploy
         ▼
┌─────────────────┐
│   Production    │
│     Ready!      │
└─────────────────┘
```

---

## Next.js 15 Breaking Changes

Be aware of these changes from Next.js 14:

1. **Params are now Promises** - await them in Route Handlers and Pages
2. **Dynamic APIs are async** - cookies(), headers(), searchParams
3. **Server Actions** - use useActionState instead of useFormState

```typescript
// Next.js 15 params pattern
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params; // Must await!
  // ...
}
```
