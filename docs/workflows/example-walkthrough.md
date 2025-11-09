# Complete SDLC Walkthrough Example

## Scenario: Building a User Management System

This document demonstrates the complete 7-phase SDLC workflow with a real-world example: building a user management system with role-based access control.

---

## Initial Input: Product Requirements Document (PRD)

```markdown
# Product Requirements Document
# User Management System v1.0

## Overview
We need a web application for managing users with role-based access control.

## Target Users
- End users (registering and using the system)
- Administrators (managing users and permissions)

## Core Features
1. User registration with email verification
2. Secure login (username/password)
3. User profile management
4. Role-based access control
   - Roles: Admin, Editor, Viewer
   - Admin can manage users and assign roles
   - Editor can modify content (to be defined later)
   - Viewer has read-only access
5. Admin dashboard for user management

## Technical Preferences
- Python backend (we have Python developers)
- Modern frontend framework
- PostgreSQL database
- Must be deployable to Kubernetes

## Compliance
- Must comply with GDPR (Europe market)

## Timeline
- Launch in 6 weeks
```

---

## Phase 1: Discovery & Requirements (Days 1-3)

### Day 1: Requirements Analysis

**User provides PRD to Main Agent**

```
User: "Here's our PRD for a user management system. Please analyze the requirements and create a detailed plan."

Main Agent: "I'll start by using the business-analyst to parse and refine these requirements."
```

**Main Agent invokes business-analyst**

**business-analyst Output:**

```markdown
## Refined Requirements

### User Stories (15 total)

1. **As a new user**, I want to register with email/password so I can access the system
   - Acceptance Criteria:
     - Email validation (RFC 5322 compliant)
     - Password requirements: min 8 chars, 1 uppercase, 1 number
     - Email verification required before access
     - Registration confirmation email sent

2. **As a registered user**, I want to log in securely so I can access my account
   - Acceptance Criteria:
     - JWT tokens with 15-minute expiry
     - Refresh token mechanism (7-day expiry)
     - Failed login attempts logged
     - Rate limiting: 5 attempts per minute

3. **As a user**, I want to update my profile so I can keep information current
   - Acceptance Criteria:
     - Update: first name, last name, avatar
     - Cannot change email (requires separate flow)
     - Changes saved immediately

4. **As an admin**, I want to view all users so I can manage the system
   - Acceptance Criteria:
     - Paginated list (20 per page)
     - Search by email or name
     - Filter by role
     - Sort by registration date

5. **As an admin**, I want to assign roles so I can control access
   - Acceptance Criteria:
     - Assign one or more roles per user
     - Cannot remove own admin role
     - Audit log of role assignments

[... 10 more user stories ...]

### Compliance Requirements (GDPR)
- User data deletion capability (within 30 days of request)
- Data export functionality
- Privacy policy displayed during registration
- Consent tracking for data processing

### Questions for Product Owner
1. Should we support OAuth (Google, GitHub)? → Adds 1 week to timeline
2. Password reset flow - email or SMS? → Recommend email
3. Two-factor authentication required? → Recommend v1.1
4. User profile photos - upload or URL? → Recommend upload to S3

### Risk Assessment
- **High Risk**: 6-week timeline is tight for all features
  - Mitigation: Prioritize MVP features, defer OAuth and 2FA to v1.1
- **Medium Risk**: GDPR compliance adds complexity
  - Mitigation: Use proven patterns, legal review before launch
```

---

### Day 2: Technology Stack & UX Design

**Main Agent invokes project-analyst**

**project-analyst Output:**

```markdown
## Technology Stack Analysis

### Recommended Stack
- **Backend**: Django 4.2 (Python 3.11) with Django REST Framework
- **Frontend**: React 18 with TypeScript
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Task Queue**: Celery (for async emails)

### Rationale
- Python preference met (Django)
- Django has excellent auth, ORM, and admin panel
- React is modern, widely supported
- PostgreSQL for relational data (roles, permissions)

### Specialist Recommendations
- django-backend-expert
- django-orm-expert
- django-api-developer
- react-component-architect
- tailwind-css-expert (for styling)
```

**Main Agent invokes ux-ui-designer**

**ux-ui-designer Output:**

```markdown
## UX/UI Design Package

### User Flows
1. Registration: Enter email → Verify email → Set password → First login
2. Login: Enter credentials → 2FA (future) → Dashboard
3. Profile Update: View profile → Edit fields → Save → Confirmation

### Wireframes (8 screens designed)
- Registration page
- Login page
- Dashboard (user view)
- Dashboard (admin view)
- User list (admin)
- User detail (admin)
- Profile edit
- Role assignment modal

### Component Specifications
- Forms: Material-inspired with floating labels
- Buttons: Primary (blue), Secondary (gray), Danger (red)
- Tables: Sortable columns, pagination controls
- Modals: For role assignment and confirmations

### Design System
- Colors: Primary #3B82F6, Secondary #64748B
- Typography: Inter font family
- Spacing: 4px base unit
- Responsive: Mobile-first, breakpoints at 640px, 1024px
```

---

### Day 3: User Approval

**Main Agent compiles Phase 1 deliverables and presents to user**

```
Main Agent: "Here's what we've gathered:
- 15 detailed user stories with acceptance criteria
- Django/React technology stack recommended
- 8 wireframe screens designed
- 4 questions requiring your input
- Risk identified: 6-week timeline is aggressive"

Questions:
1. OAuth support? → User: "No, defer to v1.1"
2. Password reset? → User: "Email-based, yes"
3. 2FA required? → User: "No, defer to v1.1"
4. Profile photos? → User: "Upload to S3, yes"

Main Agent: "Based on your answers, we'll proceed with:
- Email/password authentication (no OAuth in v1.0)
- Password reset via email
- Profile photo uploads (S3)
- Target: MVP in 5 weeks, 1 week buffer for testing/deployment"
```

**✅ APPROVAL GATE 1: User approves requirements and designs**

---

## Phase 2: Architecture & Planning (Days 4-6)

### Day 4: System Architecture

**Main Agent invokes tech-lead-orchestrator**

**tech-lead Output:**

```markdown
## System Architecture

### Components
1. **Django Backend** (API)
   - Authentication service
   - User management service
   - Role/permission service

2. **React Frontend** (SPA)
   - Public pages (login, register)
   - User dashboard
   - Admin panel

3. **PostgreSQL Database**
   - Users, roles, permissions tables

4. **Redis Cache**
   - Session storage
   - Permission caching

5. **Celery Workers**
   - Email sending (async)

### Agent Routing Map
- **Phase 3 Backend**: django-backend-expert → django-orm-expert → django-api-developer
- **Phase 3 Frontend**: react-component-architect → tailwind-css-expert
- **Phase 3 Security**: security-expert (review all auth code)
- **Phase 3 Testing**: testing-expert, code-reviewer
```

---

### Day 5: Database & API Design

**Main Agent invokes database-architect**

**database-architect Output:**

```sql
-- Schema design
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE user_roles (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE permissions (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(20) NOT NULL
);

CREATE TABLE role_permissions (
    role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
    permission_id INTEGER REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- Performance indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created ON users(created_at DESC);
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
```

**Main Agent invokes api-architect**

**api-architect Output:**

```markdown
## API Specification

### Authentication Endpoints
- POST /api/v1/auth/register
- POST /api/v1/auth/login
- POST /api/v1/auth/logout
- POST /api/v1/auth/refresh (refresh JWT)
- POST /api/v1/auth/password-reset
- POST /api/v1/auth/verify-email

### User Endpoints
- GET /api/v1/users (list, admin only)
- GET /api/v1/users/:id
- PUT /api/v1/users/:id
- DELETE /api/v1/users/:id (admin only)
- POST /api/v1/users/:id/roles (admin only)
- DELETE /api/v1/users/:id/roles/:roleId (admin only)

### OpenAPI spec generated (swagger.yaml)
```

---

### Day 6: Sprint Planning

**Main Agent invokes sprint-planner**

**sprint-planner Output:**

```markdown
## Sprint Plan (4 sprints × 1 week each)

### Sprint 1: Foundation (Week 1)
- Database setup (3 pts)
- User registration API (5 pts)
- User login API (5 pts)
- Frontend: Login/Register forms (5 pts)
- **Total**: 18 points

### Sprint 2: User Management (Week 2)
- User CRUD APIs (8 pts)
- Role assignment API (5 pts)
- Frontend: User list, user detail (8 pts)
- **Total**: 21 points

### Sprint 3: Profile & Features (Week 3)
- Profile update (3 pts)
- Avatar upload (S3) (5 pts)
- Password reset flow (5 pts)
- Email verification (3 pts)
- Frontend: Profile page (5 pts)
- **Total**: 21 points

### Sprint 4: Polish & Testing (Week 4)
- Permission checks throughout (5 pts)
- E2E testing (8 pts)
- Code review fixes (5 pts)
- Documentation (3 pts)
- **Total**: 21 points

### Week 5: Integration Testing & Deployment Prep
### Week 6: Deployment & Launch
```

**Main Agent compiles Phase 2 deliverables**

```
Main Agent: "Architecture complete:
- System architecture with 5 components
- Database schema (5 tables, 3 indexes)
- API specification (12 endpoints)
- 4-sprint plan (81 story points)
- Timeline: 4 weeks development, 2 weeks deployment = 6 weeks total ✅"
```

**✅ APPROVAL GATE 2: User approves architecture and sprint plan**

---

## Phase 3: Implementation (Weeks 1-4)

### Sprint 1: Foundation (Week 1, Days 7-13)

#### Days 7-8: Database Setup

**Main Agent invokes database-architect**

```python
# migrations/0001_initial.py
# [Database migration code created]

# Run migration
python manage.py migrate
```

#### Days 8-10: Backend APIs

**Main Agent invokes django-orm-expert**

```python
# users/models.py
class User(AbstractBaseUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    email = models.EmailField(unique=True)
    # [Full model implementation]

class Role(models.Model):
    name = models.CharField(max_length=50, unique=True)
    # [Full model implementation]
```

**Main Agent invokes django-api-developer**

```python
# users/views.py
@api_view(['POST'])
def register(request):
    # [Registration endpoint implementation]
    # - Validate email/password
    # - Hash password (bcrypt)
    # - Send verification email (via Celery)
    # - Return user data + JWT
```

**Main Agent invokes security-expert**

```
security-expert review:
✅ Passwords hashed with bcrypt
✅ JWT tokens properly signed
✅ Rate limiting on /auth/login
⚠️ Add CSRF protection → FIXED
```

#### Days 10-12: Frontend

**Main Agent invokes react-component-architect**

```tsx
// src/pages/Login.tsx
export const LoginPage = () => {
  // [Login form implementation]
  // - Email/password inputs
  // - Form validation
  // - API integration
  // - Error handling
};
```

**Main Agent invokes tailwind-css-expert**

```tsx
// Styled components with Tailwind
<button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
  Log In
</button>
```

#### Days 12-13: Testing & Review

**Main Agent invokes testing-expert**

```python
# users/tests/test_auth.py
def test_user_registration():
    response = client.post('/api/v1/auth/register', {
        'email': 'test@example.com',
        'password': 'SecurePass123!'
    })
    assert response.status_code == 201
    # [Full test implementation]
```

**Main Agent invokes code-reviewer**

```
Code Review Report:
✅ 15/15 critical checks passed
⚠️ 3 minor style issues → FIXED
✅ Test coverage: 89%
✅ Security review: PASSED
```

---

### Sprints 2-4: [Similar process, features added incrementally]

---

## Phase 4: Integration & Testing (Week 5, Days 28-32)

### Days 28-30: E2E Testing

**Main Agent invokes integration-tester**

**integration-tester Output:**

```markdown
## E2E Test Results

### Scenarios Tested: 12
- ✅ Complete registration flow (3.2s)
- ✅ Email verification flow (2.1s)
- ✅ Login flow (1.8s)
- ✅ Profile update (2.4s)
- ✅ Password reset (4.5s)
- ✅ Admin: User list pagination (1.9s)
- ✅ Admin: Role assignment (2.3s)
- ✅ Admin: User deletion (2.1s)
- ✅ Permission: Editor cannot delete users (1.2s)
- ✅ Cross-browser: Chrome, Firefox, Safari
- ✅ Mobile responsive: iPhone, Android
- ✅ Performance: All endpoints < 200ms

### Pass Rate: 100% (12/12)

### Performance:
- Avg response time: 124ms
- 95th percentile: 287ms
- Load test (1000 users): PASSED
```

### Days 30-32: Bug Fixes & Final QA

**Main Agent invokes qa-coordinator**

```markdown
## Quality Report

- Test coverage: 87%
- E2E pass rate: 100%
- Security scan: No vulnerabilities
- Performance: Within targets
- Code review: All issues resolved

**Release Readiness**: ✅ READY FOR DEPLOYMENT
```

---

## Phase 5: Deployment Preparation (Week 5-6, Days 33-36)

### Day 33-34: CI/CD & Infrastructure

**Main Agent invokes devops-cicd-expert**

**devops-cicd-expert Output:**

```yaml
# .github/workflows/deploy.yml
# [CI/CD pipeline created]
# - Automated testing
# - Docker build
# - Kubernetes deployment

# Dockerfile created (multi-stage build)
# Kubernetes manifests created
# Infrastructure as Code (Terraform) created
```

### Day 35: Security Audit

**Main Agent invokes security-auditor**

**security-auditor Output:**

```markdown
## Security Audit Report

### OWASP Top 10: ✅ PASSED

### Issues Found:
- HIGH-001: Missing security headers → FIXED
- HIGH-002: JWT not invalidated on logout → FIXED
- MED-001: Insufficient auth failure logging → FIXED
- MED-002: No rate limit on registration → FIXED

### Final Status: ✅ APPROVED FOR PRODUCTION
- Critical issues: 0
- High priority: 0 (all fixed)
- Medium priority: 0 (all fixed)
```

### Day 36: Release Planning

**Main Agent invokes release-manager**

**release-manager Output:**

```markdown
## Release Plan v1.0.0

### Deployment Strategy: Rolling Deployment
- Zero downtime
- Gradual rollout (33% → 67% → 100%)
- 15-minute rollback procedure ready

### Pre-Deployment Checklist: ✅ ALL COMPLETE
- Database backup: ✅
- Migrations tested: ✅
- Security audit: ✅
- Monitoring configured: ✅
- Rollback plan: ✅
- Stakeholders notified: ✅

### Go/No-Go: ✅ GO FOR DEPLOYMENT
```

**Main Agent presents to user**

```
Main Agent: "Deployment preparation complete:
- CI/CD pipeline configured
- Security audit passed (all issues fixed)
- Release plan ready (rolling deployment, zero downtime)
- Monitoring and alerts configured
- Ready for production deployment"
```

**✅ APPROVAL GATE 3: User approves deployment to production**

---

## Phase 6: Deployment & Launch (Day 37)

### Morning: Deployment Execution

**Main Agent invokes deployment-engineer (via release-manager)**

```bash
# 9:00 AM: Deployment begins
# 9:02 AM: Database backup complete
# 9:05 AM: Migrations applied
# 9:08 AM: Pod 1 deployed (33%)
# 9:10 AM: Health check passed
# 9:12 AM: Pod 2 deployed (67%)
# 9:14 AM: Health check passed
# 9:16 AM: Pod 3 deployed (100%)
# 9:18 AM: All pods running
# 9:20 AM: Smoke tests PASSED
# 9:23 AM: Deployment COMPLETE ✅
```

**Main Agent invokes monitoring-specialist**

**monitoring-specialist Output:**

```markdown
## Monitoring Configured

### Dashboards Created:
- Application health dashboard
- Performance metrics
- Error tracking
- User activity

### Alerts Configured:
- Error rate > 5%
- Response time > 500ms
- Pod down
- Memory usage > 85%

### Status: ✅ ALL SYSTEMS OPERATIONAL
```

**deployment-engineer Output:**

```markdown
## Deployment Report

**Status**: ✅ SUCCESS
**Duration**: 23 minutes
**Downtime**: 0 minutes
**Smoke Tests**: 8/8 PASSED
**Issues**: None

**Post-Deployment Metrics**:
- Error rate: 0%
- Avg response time: 98ms
- Active pods: 3/3
- Memory usage: 187MB avg

**Recommendation**: Monitor for 24 hours, all systems healthy
```

---

## Phase 7: Post-Launch (Days 38+)

### Day 38-44 (Week 1 Post-Launch): Monitoring

**Main Agent invokes monitoring-specialist**

**monitoring-specialist Weekly Report:**

```markdown
## Week 1 Health Report

**Overall Health**: ✅ EXCELLENT
- Uptime: 99.97%
- Avg Response Time: 102ms
- Error Rate: 0.08%
- Total Requests: 245,890
- New Users: 1,234

### Incidents: 1 Minor
- Nov 15, 2:00 PM: Brief elevated error rate (8 min)
- Root cause: Database connection pool exhausted
- Resolution: Increased pool size 10 → 20
- Impact: 0.3% of requests affected

### Recommendations:
1. Cache permission checks (reduce DB load)
2. Optimize image uploads (currently slow at 245ms)
```

---

### Day 45+: Iteration Planning

**Main Agent invokes analytics-specialist**

**analytics-specialist Output:**

```markdown
## Product Analytics (Month 1)

**User Metrics**:
- Total Users: 3,892
- Active Users: 2,567 (66%)
- Day 30 Retention: 41%

**Feature Adoption**:
- Profile Update: 61%
- Avatar Upload: 34%
- Password Reset: 12% (of those who needed it)

**Feature Requests (Top 5)**:
1. OAuth login (Google) - 89 requests
2. Two-factor authentication - 67 requests
3. Dark mode - 45 requests
4. Export user data - 34 requests
5. Custom permissions - 28 requests
```

**Main Agent invokes product-analyst**

**product-analyst Output:**

```markdown
## Sprint 5 Backlog

### High Priority:
1. **OAuth Login (Google)** - 89 user requests
   - Effort: 5 days
   - ROI: High (reduces registration friction)

2. **Two-Factor Authentication** - 67 requests
   - Effort: 5 days
   - ROI: High (enterprise requirement)

### Medium Priority:
3. **Dark Mode** - 45 requests
   - Effort: 2 days
   - ROI: Medium (UX improvement)

4. **Permission Caching** - Internal optimization
   - Effort: 1 day
   - ROI: High (performance + cost savings)

**Recommended Sprint 5 Scope**:
- OAuth Login
- Two-Factor Authentication
- Permission Caching
- Dark Mode
**Total**: 13 days (fits in 2-week sprint)
```

**Main Agent presents to user**

```
Main Agent: "First month post-launch summary:
- 3,892 users registered
- 99.97% uptime
- 1 minor incident (resolved in 8 minutes)
- User feedback: Request OAuth and 2FA

Proposed Sprint 5:
1. OAuth login (Google)
2. Two-factor authentication
3. Permission caching optimization
4. Dark mode

Ready to start Sprint 5?"
```

**User approves Sprint 5**

**Main Agent returns to Phase 3 for Sprint 5 implementation** ♻️

---

## Summary: Complete Timeline

| Week | Phase | Key Deliverables |
|------|-------|------------------|
| 1 (Days 1-3) | Phase 1: Discovery | Requirements, designs, tech stack |
| 1 (Days 4-6) | Phase 2: Architecture | Architecture, API spec, sprint plan |
| 2 (Days 7-13) | Phase 3: Sprint 1 | Foundation (auth, database) |
| 3 (Days 14-20) | Phase 3: Sprint 2 | User management |
| 4 (Days 21-27) | Phase 3: Sprint 3 | Profile features |
| 5 (Days 28-32) | Phase 4: Integration | E2E testing, QA |
| 5-6 (Days 33-36) | Phase 5: Deployment Prep | CI/CD, security audit, release plan |
| 6 (Day 37) | Phase 6: Deployment | Production launch ✅ |
| 6+ (Days 38+) | Phase 7: Post-Launch | Monitoring, iteration planning |

**Total Timeline**: 6 weeks from PRD to production ✅

---

## Key Success Factors

### What Made This Successful:

1. **Clear Requirements Early**: business-analyst caught ambiguities in Day 1
2. **User Approval Gates**: User could course-correct before costly mistakes
3. **Agile Sprints**: Delivered working software every week
4. **Quality Gates**: No critical bugs reached production
5. **Security First**: security-auditor caught issues before deployment
6. **Monitoring Ready**: Caught and fixed production issue in 8 minutes
7. **Agent Coordination**: Each agent had clear responsibilities, smooth handoffs
8. **Continuous Iteration**: Immediately planned Sprint 5 based on user feedback

---

## Agent Utilization Summary

**Total Agents Used**: 18

**Phase 1** (3 agents):
- business-analyst
- project-analyst
- ux-ui-designer

**Phase 2** (4 agents):
- tech-lead-orchestrator
- database-architect
- api-architect
- sprint-planner

**Phase 3** (7 agents):
- django-backend-expert
- django-orm-expert
- django-api-developer
- react-component-architect
- tailwind-css-expert
- security-expert
- testing-expert
- code-reviewer
- performance-optimizer
- documentation-specialist

**Phase 4** (2 agents):
- integration-tester
- qa-coordinator

**Phase 5** (3 agents):
- devops-cicd-expert
- release-manager
- security-auditor

**Phase 6** (2 agents):
- deployment-engineer
- monitoring-specialist

**Phase 7** (4 agents):
- monitoring-specialist
- incident-responder
- analytics-specialist
- product-analyst

---

## Lessons Learned

### For Future Projects:

1. **Start with Minimum Viable Features**: Deferring OAuth and 2FA to v1.1 kept timeline on track
2. **Load Testing Matters**: Week 1 incident could've been caught with realistic DB load tests
3. **Security Can't Wait**: security-auditor found issues that would've been costly post-launch
4. **User Feedback is Gold**: Analytics showed what features users actually want (OAuth #1)
5. **Agent Handoffs Need Structure**: Clear output formats from each agent ensured smooth coordination

---

## Conclusion

This walkthrough demonstrated how the 7-phase SDLC workflow with specialized agents delivers:
- ✅ On-time delivery (6 weeks)
- ✅ High quality (99.97% uptime)
- ✅ Security compliance (GDPR, OWASP Top 10)
- ✅ User satisfaction (41% retention)
- ✅ Continuous improvement (Sprint 5 planned immediately)

**The workflow is now a continuous loop of innovation and improvement** ♻️