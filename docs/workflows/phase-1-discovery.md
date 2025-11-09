# Phase 1: Discovery & Requirements

## Overview

**Duration**: 2-3 days
**Objective**: Transform Product Requirements Document (PRD) into actionable technical specifications
**Approval Gate**: ✅ User reviews and approves requirements and design direction

This phase ensures the team fully understands what needs to be built before any architecture or implementation begins.

---

## Agents in This Phase

### 1. business-analyst

**Status**: 🔴 NEW - Priority: CRITICAL
**Role**: Requirements gathering, stakeholder communication, acceptance criteria definition

#### Responsibilities

- Parse and analyze the Product Requirements Document (PRD)
- Identify ambiguities, gaps, and missing information
- Clarify business objectives and success metrics
- Define user personas and create user stories
- Write acceptance criteria for each feature
- Identify regulatory and compliance requirements (GDPR, HIPAA, SOC2, etc.)
- Map out business rules and constraints
- Conduct risk assessment

#### Input

- Product Requirements Document (PRD) from user
- Any existing project documentation
- Business context and goals

#### Output

```
## Refined Requirements Document

### Business Objectives
- Primary goal: [e.g., Increase user engagement by 30%]
- Success metrics: [e.g., DAU, conversion rate, revenue]

### User Personas
1. **Primary User**: [Description, needs, pain points]
2. **Secondary User**: [Description, needs, pain points]

### User Stories
1. As a [persona], I want to [action] so that [benefit]
   - Acceptance Criteria:
     - Given [context]
     - When [action]
     - Then [expected result]

### Business Rules
- [Rule 1: e.g., Users must verify email before accessing features]
- [Rule 2: e.g., Free tier limited to 10 projects]

### Compliance Requirements
- [e.g., GDPR: User data deletion within 30 days]
- [e.g., HIPAA: Encrypted PHI storage]

### Questions for Product Owner
1. [Ambiguity or gap requiring clarification]
2. [Missing information needed]

### Risk Assessment
- **High Risk**: [Identified risks that could derail project]
- **Medium Risk**: [Risks that need monitoring]
- **Mitigation Strategies**: [How to address risks]
```

#### Example Invocation

```
User: "Here's our PRD for a project management tool..."

Main Agent: "I'll use the business-analyst to parse and refine these requirements."
[Invokes business-analyst with PRD]

business-analyst returns:
- 15 user stories with acceptance criteria
- 3 compliance requirements identified
- 5 questions requiring clarification
- Risk assessment highlighting API integration complexity
```

---

### 2. project-analyst

**Status**: ✅ EXISTING
**Role**: Technology stack detection and project context analysis

#### Responsibilities

- Detect existing frameworks and technologies (if extending existing project)
- Identify current architecture patterns
- Assess technical constraints and limitations
- Analyze integration points with existing systems
- Generate technology compatibility report
- Flag uncertainties or assumptions

#### Input

- Existing codebase (if available)
- Technology preferences (for greenfield projects)
- Integration requirements

#### Output

```
## Technology Stack Analysis

### Detected Stack
- **Backend**: Django 4.2 (Python 3.11)
- **Frontend**: React 18 with TypeScript
- **Database**: PostgreSQL 15
- **Additional**: Redis (caching), Celery (tasks)

### Architecture Patterns
- RESTful API with Django REST Framework
- React SPA with React Router
- Token-based authentication (JWT)

### Integration Points
- Stripe API (payments)
- SendGrid (email)
- AWS S3 (file storage)

### Technical Constraints
- Must maintain backward compatibility with v2 API
- Database migration must be zero-downtime
- Multi-tenancy required (tenant-per-schema)

### Specialist Recommendations
Based on detected stack, recommend:
- django-backend-expert
- django-orm-expert
- django-api-developer
- react-component-architect

### Key Findings
- Current test coverage: 67%
- Performance bottleneck in user query endpoint
- Legacy authentication code needs refactoring

### Uncertainties
- OAuth provider not configured (need clarification)
- Deployment target unclear (AWS vs. on-prem)
```

#### Example Invocation

```
Main Agent: "I'll use project-analyst to detect the technology stack."
[Invokes project-analyst with codebase path]

project-analyst returns:
- Django/React stack detected
- Recommends Django and React specialists
- Flags OAuth configuration as unclear
```

---

### 3. ux-ui-designer

**Status**: 🔴 NEW - Priority: MEDIUM
**Role**: User experience and interface design

#### Responsibilities

- Create user flow diagrams
- Design wireframes and mockups
- Define component hierarchy
- Establish design system and style guide
- Ensure accessibility compliance (WCAG 2.1 AA)
- Create mobile-responsive design patterns
- Design error states and edge cases
- Prototype interactions

#### Input

- User stories and acceptance criteria (from business-analyst)
- Brand guidelines (if available)
- Existing design system (if extending project)

#### Output

```
## UX/UI Design Package

### User Flows
1. **User Registration Flow**
   [Start] → Enter Email → Verify Email → Set Password → [Complete]

2. **Project Creation Flow**
   [Dashboard] → New Project → Enter Details → Select Template → [Project Created]

### Wireframes
- Login Page: [Link to Figma/sketch]
- Dashboard: [Link to wireframe]
- Project Detail: [Link to wireframe]

### Component Specifications

#### Primary Button
- Sizes: Small (32px), Medium (40px), Large (48px)
- States: Default, Hover, Active, Disabled, Loading
- Colors: Primary (blue), Secondary (gray), Danger (red)

#### Input Field
- Label positioning: Top-aligned
- Validation: Real-time with error messages below
- States: Default, Focus, Error, Disabled

### Design System

#### Typography
- Headings: Inter Bold (H1: 32px, H2: 24px, H3: 20px)
- Body: Inter Regular (16px, line-height: 1.5)
- Code: Fira Code (14px)

#### Color Palette
- Primary: #3B82F6
- Secondary: #64748B
- Success: #10B981
- Error: #EF4444
- Warning: #F59E0B

#### Spacing Scale
- 4px, 8px, 12px, 16px, 24px, 32px, 48px, 64px

### Accessibility Guidelines
- Color contrast ratio: Minimum 4.5:1 for normal text
- Focus indicators: 2px solid outline on all interactive elements
- Keyboard navigation: Logical tab order
- Screen reader: Proper ARIA labels and semantic HTML

### Responsive Breakpoints
- Mobile: < 640px
- Tablet: 640px - 1024px
- Desktop: > 1024px

### Interaction Patterns
- Loading states: Skeleton screens for data fetching
- Empty states: Helpful illustrations with CTAs
- Error handling: Toast notifications (top-right, 5s auto-dismiss)

### Design Deliverables
- Figma file with all screens: [Link]
- Component library: [Link]
- Design tokens (JSON): [Link]
```

#### Example Invocation

```
Main Agent: "I'll use ux-ui-designer to create wireframes for the user management feature."
[Invokes ux-ui-designer with user stories]

ux-ui-designer returns:
- User flow diagrams for registration and login
- Wireframes for 8 key screens
- Component specifications for forms and buttons
- Accessibility compliance checklist
```

---

## Phase 1 Workflow

### Step-by-Step Execution

```
1. Main Agent receives PRD from user

2. Main Agent invokes business-analyst
   ├─ Parses PRD
   ├─ Creates user stories
   ├─ Identifies compliance needs
   └─ Flags questions for user

3. Main Agent invokes project-analyst (if existing project)
   ├─ Detects technology stack
   ├─ Analyzes architecture
   └─ Recommends specialists

4. Main Agent presents questions to user (if any)
   └─ User provides clarifications

5. Main Agent invokes ux-ui-designer
   ├─ Creates user flows
   ├─ Designs wireframes
   ├─ Defines component specs
   └─ Ensures accessibility

6. Main Agent compiles Phase 1 deliverables

7. APPROVAL GATE 1: Present to user
   ├─ Refined requirements
   ├─ User stories with acceptance criteria
   ├─ Technology stack analysis
   ├─ UX/UI designs
   └─ Risk assessment

8. User reviews and approves (or requests changes)
   ✅ If approved → Proceed to Phase 2
   ❌ If changes needed → Iterate on requirements
```

---

## Deliverables Checklist

Before exiting Phase 1, ensure these deliverables are complete:

- [ ] **Refined Requirements Document**
  - [ ] Business objectives clearly defined
  - [ ] User personas documented
  - [ ] User stories with acceptance criteria
  - [ ] Business rules documented
  - [ ] Compliance requirements identified

- [ ] **Technology Stack Analysis** (if applicable)
  - [ ] Current stack detected and documented
  - [ ] Architecture patterns identified
  - [ ] Integration points mapped
  - [ ] Specialist agents recommended

- [ ] **UX/UI Design Package**
  - [ ] User flows created
  - [ ] Wireframes for key screens
  - [ ] Component specifications defined
  - [ ] Design system established
  - [ ] Accessibility guidelines documented

- [ ] **Risk Assessment**
  - [ ] Technical risks identified
  - [ ] Business risks documented
  - [ ] Mitigation strategies proposed

- [ ] **Outstanding Questions Resolved**
  - [ ] All ambiguities clarified with user
  - [ ] Assumptions validated

---

## Common Pitfalls to Avoid

### 1. Insufficient Requirements Gathering
**Problem**: Moving forward with vague or incomplete requirements
**Solution**: business-analyst should flag ALL ambiguities and get clarification before approval

### 2. Skipping UX Design
**Problem**: Building features without considering user experience
**Solution**: Always create wireframes and user flows before implementation

### 3. Ignoring Compliance
**Problem**: Discovering GDPR/HIPAA requirements during deployment
**Solution**: business-analyst must identify regulatory requirements upfront

### 4. Technology Mismatch
**Problem**: Choosing tech stack that doesn't fit requirements
**Solution**: project-analyst validates technology choices against constraints

### 5. No Risk Assessment
**Problem**: Surprised by technical or business risks mid-project
**Solution**: Conduct thorough risk analysis and create mitigation plans

---

## Example: Phase 1 for User Management System

### Input: PRD Excerpt
```
"We need a user management system with role-based access control.
Users should be able to register, login, manage their profile,
and administrators should assign roles and permissions."
```

### business-analyst Output

**User Stories Created**:
1. As a new user, I want to register with email/password so I can access the system
2. As a registered user, I want to log in securely so I can access my account
3. As a user, I want to update my profile so I can keep my information current
4. As an admin, I want to assign roles to users so I can control access
5. As an admin, I want to define custom permissions so I can fine-tune access control

**Compliance Requirements**:
- GDPR: User data deletion capability
- Password security: Bcrypt/Argon2, minimum 8 characters

**Questions Raised**:
- Should we support OAuth (Google, GitHub)?
- What are the default roles (Admin, User, Guest)?
- Password reset flow - email or SMS?

### project-analyst Output

**Detected Stack**:
- Django 4.2, PostgreSQL, React

**Recommendations**:
- Use django-backend-expert
- Use django-orm-expert (for User/Role/Permission models)
- Use django-api-developer (for REST endpoints)

### ux-ui-designer Output

**Wireframes Created**:
- Registration form (email, password, confirm password)
- Login form (email, password, "Forgot password?" link)
- Profile page (editable fields, avatar upload)
- Admin role management (user list, role dropdown)

**Component Specs**:
- Form inputs with real-time validation
- Error states for invalid credentials
- Loading states for async operations

### APPROVAL GATE 1

Main Agent presents to user:
- 5 user stories with acceptance criteria
- Technology recommendations (Django specialists)
- Wireframes for 4 key screens
- 3 questions requiring answers

User responds:
- OAuth: Yes, support Google OAuth
- Default roles: Admin, Editor, Viewer
- Password reset: Email-based

✅ User approves requirements → Proceed to Phase 2

---

## Next Phase

Once Phase 1 is approved, hand off to [Phase 2: Architecture & Planning](./phase-2-architecture.md)