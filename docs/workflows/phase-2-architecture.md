# Phase 2: Architecture & Planning

## Overview

**Duration**: 3-4 days
**Objective**: Create technical blueprint and sprint plan
**Approval Gate**: ✅ User approves architecture and sprint plan
**Prerequisites**: Phase 1 requirements and designs approved

This phase transforms requirements into a concrete technical plan with clear execution strategy.

---

## Agents in This Phase

### 1. tech-lead-orchestrator

**Status**: ✅ EXISTING (may need enhancement)
**Role**: Technical architecture and agent delegation strategy

#### Responsibilities

- Define high-level system architecture
- Create component breakdown structure
- Assign tasks to specialist agents (agent routing map)
- Define integration points between components
- Identify technical risks and mitigation strategies
- Make technology stack decisions (for greenfield projects)
- Define development phases and dependencies

#### Input

- Approved requirements from Phase 1
- User stories with acceptance criteria
- Technology stack analysis (from project-analyst)
- UX/UI designs and component specs

#### Output

```
## System Architecture Document

### Architecture Pattern
- **Style**: Microservices / Monolithic / Serverless
- **Communication**: REST API / GraphQL / Event-driven

### System Components

#### Backend Services
1. **Authentication Service**
   - Handles user registration, login, JWT tokens
   - Dependencies: Database, Redis (sessions)

2. **User Management Service**
   - CRUD operations for users, roles, permissions
   - Dependencies: Database, Authentication Service

3. **API Gateway**
   - Route requests to appropriate services
   - Rate limiting, request validation
   - Dependencies: All backend services

#### Frontend Applications
1. **Web Application (React SPA)**
   - User interface for all features
   - State management with Redux
   - Dependencies: API Gateway

#### Data Layer
1. **PostgreSQL Database**
   - User data, roles, permissions
   - Schema design by database-architect

2. **Redis Cache**
   - Session storage
   - API response caching

### Integration Points
- Authentication Service ←→ User Management (JWT validation)
- Frontend ←→ API Gateway (REST/JSON)
- All Services ←→ Database (via ORM)

### Agent Routing Map

**Phase 3 Implementation:**
- **Task 1**: Database schema design
  - PRIMARY: database-architect

- **Task 2**: Authentication service implementation
  - PRIMARY: django-backend-expert
  - SUPPORTING: security-expert

- **Task 3**: User management API
  - PRIMARY: django-api-developer
  - SUPPORTING: django-orm-expert

- **Task 4**: Frontend components
  - PRIMARY: react-component-architect
  - SUPPORTING: tailwind-css-expert

### Technical Risks
- **Risk 1**: OAuth integration complexity
  - Mitigation: Use proven library (django-allauth)
  - Assign to: security-expert for review

- **Risk 2**: Database migration strategy
  - Mitigation: Zero-downtime migration plan
  - Assign to: database-architect

### Execution Order
```
Parallel Stream 1 (Backend):
  database-architect → django-backend-expert → django-api-developer

Parallel Stream 2 (Frontend):
  react-component-architect → tailwind-css-expert

Cross-cutting (Throughout):
  security-expert, testing-expert, code-reviewer
```
```

#### Example Invocation

```
Main Agent: "I'll use tech-lead-orchestrator to design the architecture."
[Invokes tech-lead with approved requirements]

tech-lead returns:
- System architecture with 5 components
- Agent routing map for 8 tasks
- Identified 3 technical risks with mitigations
- Execution plan (2 parallel streams)
```

---

### 2. database-architect

**Status**: 🔴 NEW - Priority: CRITICAL
**Role**: Data modeling and database design

#### Responsibilities

- Design entity-relationship diagrams (ERD)
- Create database schema (tables, columns, constraints)
- Define indexes for performance
- Plan migration strategy
- Design data access patterns
- Consider scalability and partitioning
- Plan backup and disaster recovery
- Define data retention policies

#### Input

- Requirements and business rules
- User stories
- Existing database schema (if extending project)
- Expected data volume and growth

#### Output

```
## Database Design Document

### Entity-Relationship Diagram

```
[User] ─────< [UserRole] >───── [Role]
   |                               |
   |                               |
   v                               v
[Profile]                    [Permission]
                                   ^
                                   |
                              [RolePermission]
```

### Schema Definition

#### Table: users
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
```

#### Table: roles
```sql
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO roles (name, description) VALUES
    ('admin', 'Full system access'),
    ('editor', 'Can create and edit content'),
    ('viewer', 'Read-only access');
```

#### Table: user_roles (Many-to-Many)
```sql
CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES users(id),
    PRIMARY KEY (user_id, role_id)
);

CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role_id);
```

#### Table: permissions
```sql
CREATE TABLE permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(20) NOT NULL,
    description TEXT
);

-- Example permissions
INSERT INTO permissions (name, resource, action) VALUES
    ('users.create', 'users', 'create'),
    ('users.read', 'users', 'read'),
    ('users.update', 'users', 'update'),
    ('users.delete', 'users', 'delete');
```

#### Table: role_permissions
```sql
CREATE TABLE role_permissions (
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INTEGER REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);
```

### Migration Strategy

**Phase 1: Core Tables**
1. Create users table
2. Create roles table
3. Seed default roles

**Phase 2: Relationships**
4. Create user_roles table
5. Create permissions table
6. Create role_permissions table

**Rollback Plan:**
- Each migration has corresponding down migration
- Backup database before applying migrations

### Data Access Patterns

**Query 1: Get User with Roles**
```sql
SELECT u.*, array_agg(r.name) as roles
FROM users u
LEFT JOIN user_roles ur ON u.id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.id
WHERE u.id = $1
GROUP BY u.id;
```

**Query 2: Check User Permission**
```sql
SELECT EXISTS (
    SELECT 1 FROM users u
    JOIN user_roles ur ON u.id = ur.user_id
    JOIN role_permissions rp ON ur.role_id = rp.role_id
    JOIN permissions p ON rp.permission_id = p.id
    WHERE u.id = $1 AND p.name = $2
);
```

### Performance Considerations

**Indexes:**
- users.email (UNIQUE) - Fast login lookup
- users.created_at - User listing/pagination
- user_roles.user_id - Permission checks
- user_roles.role_id - Role management

**Estimated Volumes:**
- Users: 100K in year 1, 500K in year 3
- Roles: ~10 (relatively static)
- Permissions: ~50 (grows with features)

**Scaling Strategy:**
- Implement read replicas for user lookups
- Consider partitioning users table by created_at if > 1M users
- Cache permission checks in Redis (TTL: 5 minutes)

### Backup and DR

- **Backup Frequency**: Daily full backup, hourly incremental
- **Retention**: 30 days of daily backups
- **DR RPO**: 1 hour (hourly backups)
- **DR RTO**: 4 hours (restore time)

### Data Retention

- **Active Users**: Indefinite
- **Deleted Users**: Soft delete for 30 days, then hard delete
- **Audit Logs**: 1 year retention
- **Sessions**: 24 hour TTL
```

#### Example Invocation

```
Main Agent: "I'll use database-architect to design the schema."
[Invokes database-architect with requirements and business rules]

database-architect returns:
- ER diagram with 6 entities
- SQL schema for 5 tables
- Migration plan (2 phases)
- Performance indexes and query patterns
- Scaling recommendations
```

---

### 3. api-architect

**Status**: ✅ EXISTING (may need enhancement)
**Role**: API design and integration strategy

#### Responsibilities

- Design RESTful or GraphQL API contracts
- Define authentication and authorization strategies
- Create API versioning strategy
- Design rate limiting and throttling rules
- Write API documentation (OpenAPI/Swagger)
- Plan WebSocket/real-time communication (if needed)
- Define error response formats
- Create API testing strategy

#### Input

- System architecture (from tech-lead)
- Database schema (from database-architect)
- Frontend requirements (from ux-ui-designer)
- Integration needs (third-party APIs)

#### Output

```
## API Specification

### Base URL
- Development: `http://localhost:8000/api/v1`
- Production: `https://api.example.com/v1`

### Authentication

**Method**: JWT (JSON Web Tokens)

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Token Lifetime:**
- Access Token: 15 minutes
- Refresh Token: 7 days

### Endpoints

#### Authentication Endpoints

**POST /auth/register**
Register a new user

Request:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "password_confirm": "SecurePass123!"
}
```

Response (201 Created):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "email_verified": false,
  "created_at": "2025-11-08T10:30:00Z"
}
```

Errors:
- 400: Validation error (email invalid, password too weak)
- 409: Email already exists

---

**POST /auth/login**
Authenticate user and receive JWT tokens

Request:
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

Response (200 OK):
```json
{
  "access_token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "token_type": "Bearer",
  "expires_in": 900,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "roles": ["editor"]
  }
}
```

Errors:
- 401: Invalid credentials
- 403: Account not verified or disabled

---

#### User Management Endpoints

**GET /users**
List users (paginated)

Query Parameters:
- `page` (default: 1)
- `page_size` (default: 20, max: 100)
- `search` (filter by email or name)
- `role` (filter by role name)

Headers Required:
- `Authorization: Bearer <token>` (requires `users.read` permission)

Response (200 OK):
```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "email": "user@example.com",
      "roles": ["editor"],
      "is_active": true,
      "created_at": "2025-11-08T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_pages": 5,
    "total_count": 95
  }
}
```

---

**GET /users/:id**
Get single user details

Response (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "email_verified": true,
  "roles": [
    {
      "id": 2,
      "name": "editor",
      "permissions": ["users.read", "users.update"]
    }
  ],
  "profile": {
    "first_name": "John",
    "last_name": "Doe",
    "avatar_url": "https://cdn.example.com/avatars/123.jpg"
  },
  "created_at": "2025-11-08T10:30:00Z",
  "last_login": "2025-11-08T14:22:00Z"
}
```

Errors:
- 404: User not found
- 403: Insufficient permissions

---

**PUT /users/:id**
Update user details

Request:
```json
{
  "profile": {
    "first_name": "Jane",
    "last_name": "Smith"
  }
}
```

Response (200 OK):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "profile": {
    "first_name": "Jane",
    "last_name": "Smith"
  },
  "updated_at": "2025-11-08T15:00:00Z"
}
```

---

**POST /users/:id/roles**
Assign role to user (Admin only)

Request:
```json
{
  "role_id": 2
}
```

Response (201 Created):
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "role_id": 2,
  "role_name": "editor",
  "assigned_at": "2025-11-08T15:05:00Z"
}
```

---

### Error Response Format

All errors follow this structure:
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Email is required"
      },
      {
        "field": "password",
        "message": "Password must be at least 8 characters"
      }
    ]
  }
}
```

### Rate Limiting

**Global Limits:**
- Authenticated users: 1000 requests/hour
- Unauthenticated: 100 requests/hour

**Endpoint-Specific:**
- POST /auth/login: 5 requests/minute (prevent brute force)
- POST /auth/register: 3 requests/hour per IP

**Headers:**
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 987
X-RateLimit-Reset: 1636372800
```

### Versioning Strategy

**Current Version**: v1

**Breaking Changes:**
- Introduce new version (v2) alongside v1
- Maintain v1 for 12 months after v2 launch
- Deprecation warnings in response headers

### OpenAPI Specification

Full OpenAPI 3.0 spec: [Link to swagger.yaml]

### Testing Strategy

- **Unit Tests**: Each endpoint handler
- **Integration Tests**: Full request/response cycle
- **Contract Tests**: API clients validate against OpenAPI spec
- **Load Tests**: 1000 concurrent users, response time < 200ms
```

#### Example Invocation

```
Main Agent: "I'll use api-architect to design the REST API."
[Invokes api-architect with database schema and requirements]

api-architect returns:
- API specification with 8 endpoints
- Authentication strategy (JWT)
- Rate limiting rules
- OpenAPI documentation
- Error response format
```

---

### 4. sprint-planner

**Status**: 🔴 NEW - Priority: MEDIUM
**Role**: Agile sprint planning and story estimation

#### Responsibilities

- Break work into sprint-sized chunks (2-week sprints)
- Estimate complexity using story points
- Prioritize features (MoSCoW: Must/Should/Could/Won't)
- Create sprint backlogs
- Define sprint goals
- Identify dependencies between tasks
- Calculate team velocity

#### Input

- System architecture and component breakdown
- Agent routing map (from tech-lead)
- User stories with acceptance criteria
- Team capacity (agent availability)

#### Output

```
## Sprint Plan

### Sprint 1: Foundation (Nov 11-24, 2025)

**Sprint Goal**: Core authentication and user management

**Stories (Total: 21 points)**

1. **Database Setup** [3 points]
   - Create database schema
   - Run migrations
   - Seed initial data (roles, permissions)
   - Agent: database-architect
   - Dependencies: None
   - Acceptance Criteria:
     - [x] All tables created
     - [x] Default roles seeded (admin, editor, viewer)
     - [x] Database accessible from backend

2. **User Registration API** [5 points]
   - Implement POST /auth/register endpoint
   - Email validation
   - Password hashing (bcrypt)
   - Send verification email
   - Agent: django-api-developer, security-expert
   - Dependencies: Story #1
   - Acceptance Criteria:
     - [x] User can register with email/password
     - [x] Password meets security requirements
     - [x] Verification email sent
     - [x] Unit tests with 80%+ coverage

3. **User Login API** [5 points]
   - Implement POST /auth/login endpoint
   - JWT token generation
   - Refresh token mechanism
   - Rate limiting (5 attempts/minute)
   - Agent: django-api-developer, security-expert
   - Dependencies: Story #2
   - Acceptance Criteria:
     - [x] User can login with valid credentials
     - [x] JWT token returned
     - [x] Invalid credentials return 401
     - [x] Rate limiting enforced

4. **Frontend: Login Form** [3 points]
   - Create login component
   - Form validation (client-side)
   - API integration
   - Error handling (toast notifications)
   - Agent: react-component-architect, tailwind-css-expert
   - Dependencies: Story #3
   - Acceptance Criteria:
     - [x] User can enter email/password
     - [x] Validation errors shown
     - [x] Successful login redirects to dashboard
     - [x] Failed login shows error message

5. **Frontend: Registration Form** [3 points]
   - Create registration component
   - Password strength indicator
   - API integration
   - Success message and redirect
   - Agent: react-component-architect
   - Dependencies: Story #2
   - Acceptance Criteria:
     - [x] User can enter registration details
     - [x] Password strength shown visually
     - [x] Successful registration shows success message
     - [x] User redirected to email verification page

6. **Code Review & Testing** [2 points]
   - Security review of auth code
   - Integration tests
   - E2E test for login/register flow
   - Agent: code-reviewer, testing-expert
   - Dependencies: All above
   - Acceptance Criteria:
     - [x] No security vulnerabilities found
     - [x] Integration tests pass
     - [x] E2E tests pass

---

### Sprint 2: User Management (Nov 25 - Dec 8, 2025)

**Sprint Goal**: CRUD operations for users and role assignment

**Stories (Total: 19 points)**

1. **User List API** [3 points]
   - GET /users endpoint
   - Pagination support
   - Search and filtering
   - Agent: django-api-developer

2. **User Detail API** [2 points]
   - GET /users/:id endpoint
   - Include roles and permissions
   - Agent: django-api-developer

3. **User Update API** [3 points]
   - PUT /users/:id endpoint
   - Profile update
   - Permission checks
   - Agent: django-api-developer, security-expert

4. **Role Assignment API** [4 points]
   - POST /users/:id/roles endpoint
   - Admin-only access
   - Audit logging
   - Agent: django-api-developer, security-expert

5. **Frontend: User Management Dashboard** [5 points]
   - User list with search
   - Pagination component
   - Role assignment UI
   - Agent: react-component-architect, tailwind-css-expert

6. **Testing & Performance** [2 points]
   - Load testing (1000 users)
   - Query optimization
   - Agent: performance-optimizer, testing-expert

---

### Priority Matrix (MoSCoW)

**Must Have (Sprint 1-2)**
- User registration and login
- Role-based access control
- User management CRUD

**Should Have (Sprint 3)**
- OAuth integration (Google)
- Password reset flow
- Email verification

**Could Have (Sprint 4+)**
- Two-factor authentication
- Custom permission creation
- Activity logs

**Won't Have (This Release)**
- SAML SSO
- LDAP integration
- Advanced audit trails

---

### Dependency Map

```
Sprint 1:
  Story 1 (DB Setup)
     ├── Story 2 (Registration API)
     │     └── Story 5 (Registration Form)
     │
     └── Story 3 (Login API)
           └── Story 4 (Login Form)

  Story 6 (Review) depends on ALL above

Sprint 2:
  Story 1, 2, 3, 4 (APIs) can run in parallel
  Story 5 (Frontend) depends on APIs
  Story 6 (Testing) depends on ALL
```

---

### Team Velocity

**Sprint 1**: 21 points (baseline)
**Sprint 2**: 19 points (adjusted for holidays)
**Sprint 3 Forecast**: 21 points (if velocity stable)

---

### Risk Items

**Risk 1**: OAuth integration more complex than estimated
- Impact: Could spill into Sprint 4
- Mitigation: Start OAuth spike in Sprint 2

**Risk 2**: Performance issues with permission checks
- Impact: Query optimization needed
- Mitigation: Include performance testing in Sprint 2
```

#### Example Invocation

```
Main Agent: "I'll use sprint-planner to create the sprint plan."
[Invokes sprint-planner with architecture and requirements]

sprint-planner returns:
- 2 sprint plans with 40 story points total
- Story breakdown with estimates
- Dependency map
- Priority matrix (MoSCoW)
- Risk items identified
```

---

## Phase 2 Workflow

### Step-by-Step Execution

```
1. Main Agent receives approved Phase 1 deliverables

2. Main Agent invokes tech-lead-orchestrator
   ├─ Analyzes requirements and designs
   ├─ Defines system architecture
   ├─ Creates component breakdown
   ├─ Generates agent routing map
   └─ Identifies technical risks

3. Main Agent invokes database-architect
   ├─ Creates ER diagrams
   ├─ Designs database schema
   ├─ Plans migrations
   └─ Defines performance indexes

4. Main Agent invokes api-architect
   ├─ Designs API endpoints
   ├─ Defines authentication strategy
   ├─ Creates OpenAPI documentation
   └─ Sets rate limiting rules

5. Main Agent invokes sprint-planner
   ├─ Breaks work into sprints
   ├─ Estimates story points
   ├─ Prioritizes features (MoSCoW)
   └─ Creates dependency map

6. Main Agent compiles Phase 2 deliverables

7. APPROVAL GATE 2: Present to user
   ├─ System architecture diagram
   ├─ Database schema and migrations
   ├─ API specification (OpenAPI)
   ├─ Sprint plan (2-3 sprints)
   └─ Risk assessment

8. User reviews and approves (or requests changes)
   ✅ If approved → Proceed to Phase 3 (Implementation)
   ❌ If changes needed → Iterate on architecture
```

---

## Deliverables Checklist

Before exiting Phase 2, ensure:

- [ ] **System Architecture Document**
  - [ ] Architecture pattern defined
  - [ ] Component breakdown complete
  - [ ] Integration points mapped
  - [ ] Agent routing map created
  - [ ] Technical risks identified with mitigations

- [ ] **Database Design**
  - [ ] ER diagrams created
  - [ ] SQL schema defined
  - [ ] Indexes planned
  - [ ] Migration strategy documented
  - [ ] Scaling plan outlined

- [ ] **API Specification**
  - [ ] All endpoints defined
  - [ ] Request/response formats documented
  - [ ] Authentication strategy defined
  - [ ] Error formats standardized
  - [ ] OpenAPI spec generated

- [ ] **Sprint Plan**
  - [ ] Work broken into 2-week sprints
  - [ ] Stories estimated (story points)
  - [ ] Features prioritized (MoSCoW)
  - [ ] Dependencies identified
  - [ ] Sprint goals defined

---

## Common Pitfalls

### 1. Over-Engineering
**Problem**: Designing for scale that won't be needed for years
**Solution**: Start simple, plan for scalability but don't build it yet

### 2. Under-Estimated Complexity
**Problem**: Missing edge cases or integration complexity
**Solution**: Tech-lead should consult specialists for estimates

### 3. Missing Dependencies
**Problem**: Sprint plan doesn't account for task dependencies
**Solution**: sprint-planner must create dependency map

### 4. No Performance Planning
**Problem**: Discovering slow queries in production
**Solution**: database-architect plans indexes upfront

### 5. API Design Inconsistency
**Problem**: Different error formats, inconsistent naming
**Solution**: api-architect establishes standards in OpenAPI spec

---

## Next Phase

Once Phase 2 is approved, begin [Phase 3: Implementation](./phase-3-implementation.md)