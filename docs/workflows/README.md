# Software Development Lifecycle (SDLC) Workflow

## Overview

This directory contains a comprehensive Software Development Lifecycle workflow designed for AI agent teams. Each agent handles specific responsibilities within the development process, from initial PRD intake through post-launch iteration.

## Workflow Characteristics

- **Methodology**: Agile/Iterative with 2-week sprints
- **Project Types**: Universal (web, mobile, desktop, APIs, microservices)
- **User Involvement**: Medium - approval required at key milestones
- **Scope**: Full lifecycle including post-launch iteration and enhancement

## The 7 Phases

### [Phase 1: Discovery & Requirements](./phase-1-discovery.md)
**Duration**: 2-3 days
**Approval Gate**: ✅ User approves requirements and design direction

Transform Product Requirements Document (PRD) into actionable specifications with:
- Business analysis and requirements refinement
- Technology stack detection
- UX/UI design and wireframing

**Key Agents**: business-analyst, project-analyst, ux-ui-designer

---

### [Phase 2: Architecture & Planning](./phase-2-architecture.md)
**Duration**: 3-4 days
**Approval Gate**: ✅ User approves architecture and sprint plan

Create technical blueprint and execution plan:
- System architecture design
- Database schema and data modeling
- API contracts and integration strategy
- Sprint planning and task estimation

**Key Agents**: tech-lead-orchestrator, database-architect, api-architect, sprint-planner

---

### [Phase 3: Implementation](./phase-3-implementation.md)
**Duration**: 2-week sprints (repeatable)
**Approval Gate**: None (continuous delivery)

Build features according to sprint plan:
- Backend development (models, controllers, APIs)
- Frontend development (components, state, routing)
- Security implementation
- Testing and code review
- Performance optimization
- Documentation

**Key Agents**: Framework-specific experts (Django, Laravel, Rails, React, Vue), testing-expert, code-reviewer, performance-optimizer

---

### [Phase 4: Integration & Testing](./phase-4-integration.md)
**Duration**: 2-3 days
**Approval Gate**: None (quality gate before deployment prep)

Validate that all components work together:
- End-to-end testing
- Integration testing
- Cross-browser/device testing
- Bug triage and fixes

**Key Agents**: integration-tester, qa-coordinator

---

### [Phase 5: Deployment Preparation](./phase-5-deployment-prep.md)
**Duration**: 2-3 days
**Approval Gate**: ✅ User approves deployment to production

Prepare application for production:
- CI/CD pipeline configuration
- Container and infrastructure setup
- Release planning and deployment strategy
- Security audit and compliance verification

**Key Agents**: devops-cicd-expert, release-manager, security-auditor

---

### [Phase 6: Deployment & Launch](./phase-6-deployment.md)
**Duration**: 1 day
**Approval Gate**: None (executed per approved plan)

Deploy to production safely:
- Production deployment execution
- Health checks and smoke testing
- Monitoring and alerting setup

**Key Agents**: deployment-engineer, monitoring-specialist

---

### [Phase 7: Post-Launch & Iteration](./phase-7-post-launch.md)
**Duration**: Ongoing
**Approval Gate**: User approves iteration priorities

Monitor, maintain, and enhance:
- Production monitoring and incident response
- Performance tracking
- Analytics and user feedback
- Enhancement backlog prioritization

**Key Agents**: monitoring-specialist, incident-responder, analytics-specialist, product-analyst

---

## Workflow Principles

### 1. Human-in-the-Loop
Three strategic approval gates ensure user control:
- **Gate 1**: After Discovery (requirements and design)
- **Gate 2**: After Architecture (technical plan and sprints)
- **Gate 3**: Before Deployment (production readiness)

### 2. Agile/Iterative Development
- 2-week sprint cycles for predictable delivery
- Potentially shippable increments after each sprint
- Continuous feedback and adaptation
- Backlog refinement between sprints

### 3. Agent Orchestration
- Main Claude agent coordinates all sub-agents
- tech-lead-orchestrator provides agent routing map
- Clear input/output contracts between agents
- Structured handoffs between phases

### 4. Quality Gates
Quality is enforced at multiple checkpoints:
- Code review before merge
- Testing (unit, integration, E2E) throughout development
- Security audit before deployment
- Performance validation in each sprint

### 5. Universal Applicability
- Automatic technology stack detection
- Framework-specific specialists when available
- Universal fallback agents for any stack
- Adapts to greenfield or legacy projects

---

## Agent Overview

### Total Agents in Workflow: 29

**Existing Agents**: 12
- Orchestrators (3): tech-lead-orchestrator, project-analyst, team-configurator
- Framework Specialists (4): django/laravel/rails/react experts
- Universal (2): backend-developer, frontend-developer, api-architect
- Core (3): code-reviewer, performance-optimizer, documentation-specialist

**New Agents Needed**: 17
- See [Agent Priority Matrix](./agent-priority-matrix.md) for creation priorities

---

## Quick Start Guide

### Starting a New Project from PRD

```
1. Provide PRD to business-analyst
   → Receives: Refined requirements + user stories

2. Run project-analyst (if extending existing project)
   → Receives: Technology stack analysis

3. Present requirements to user for approval (Gate 1)
   ✅ USER APPROVES

4. Run tech-lead-orchestrator with approved requirements
   → Receives: System architecture + agent routing map

5. Run database-architect and api-architect
   → Receives: Database schema + API specifications

6. Run sprint-planner
   → Receives: Sprint plan with estimated tasks

7. Present architecture and plan to user (Gate 2)
   ✅ USER APPROVES

8. Execute Sprint 1:
   - Days 1-10: Implementation (backend, frontend, security)
   - Days 11-12: Testing and review
   - Days 13-14: Documentation and refinement

9. Run integration testing
   → Receives: E2E test results + bug reports

10. Prepare deployment:
    - CI/CD pipeline setup
    - Security audit
    - Release plan

11. Present deployment plan to user (Gate 3)
    ✅ USER APPROVES

12. Deploy to production with monitoring

13. Begin post-launch monitoring and iteration planning
```

---

## Example Scenarios

### [Complete Feature Build Example](./example-walkthrough.md)
See a detailed walkthrough of building a user management system from PRD to production deployment.

---

## Additional Resources

- **[Agent Priority Matrix](./agent-priority-matrix.md)** - Prioritized list of agents to create
- **[Agent Dependency Map](./agent-priority-matrix.md#dependency-map)** - Visual representation of agent coordination

---

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        INPUT: PRD                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    ┌────────▼─────────┐
                    │   PHASE 1        │
                    │   Discovery      │
                    │   & Requirements │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  APPROVAL GATE 1  │ ◄── User reviews requirements
                    │  Requirements OK? │
                    └────────┬─────────┘
                             │ ✅
                    ┌────────▼─────────┐
                    │   PHASE 2        │
                    │   Architecture   │
                    │   & Planning     │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  APPROVAL GATE 2  │ ◄── User reviews architecture
                    │  Architecture OK? │
                    └────────┬─────────┘
                             │ ✅
                ┌────────────▼────────────┐
                │   PHASE 3               │
                │   Implementation        │
                │   (Sprint 1, 2, 3...)   │ ◄── Iterative sprints
                └────────────┬────────────┘
                             │
                    ┌────────▼─────────┐
                    │   PHASE 4        │
                    │   Integration    │
                    │   & Testing      │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │   PHASE 5        │
                    │   Deployment     │
                    │   Preparation    │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  APPROVAL GATE 3  │ ◄── User approves deployment
                    │  Deploy to Prod?  │
                    └────────┬─────────┘
                             │ ✅
                    ┌────────▼─────────┐
                    │   PHASE 6        │
                    │   Deployment     │
                    │   & Launch       │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │   PHASE 7        │
                    │   Post-Launch    │
                    │   & Iteration    │ ◄── Continuous improvement
                    └──────────────────┘
```

---

## Notes

- Each phase document contains detailed agent specifications
- Agent responsibilities, inputs, and outputs are clearly defined
- Examples demonstrate real-world application
- Priority matrix helps with incremental agent creation
