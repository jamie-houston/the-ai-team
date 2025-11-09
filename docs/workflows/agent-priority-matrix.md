# Agent Priority Matrix

## Overview

This document provides a prioritized roadmap for creating the agents needed to support the complete SDLC workflow. Agents are categorized by priority based on:
- **Criticality**: How essential they are to the workflow
- **Gap Analysis**: Whether existing agents cover this need
- **Impact**: Value delivered to the development process

---

## Agent Inventory

### Existing Agents: 20

**Orchestrators** (3):
- ✅ tech-lead-orchestrator
- ✅ project-analyst
- ✅ team-configurator

**Framework Specialists** (13):
- ✅ django-backend-expert
- ✅ django-orm-expert
- ✅ django-api-developer
- ✅ laravel-backend-expert
- ✅ laravel-eloquent-expert
- ✅ rails-backend-expert
- ✅ rails-activerecord-expert
- ✅ rails-api-developer
- ✅ react-component-architect
- ✅ react-nextjs-expert
- ✅ vue-component-architect
- ✅ vue-nuxt-expert
- ✅ vue-state-manager

**Universal Experts** (4):
- ✅ backend-developer
- ✅ frontend-developer
- ✅ api-architect
- ✅ tailwind-css-expert

**Core Team** (4):
- ✅ code-archaeologist
- ✅ code-reviewer
- ✅ performance-optimizer
- ✅ documentation-specialist

**Python Specialists** (5):
- ✅ python-testing-expert (needs expansion to multi-language)
- ✅ python-security-expert (needs expansion to multi-language)
- ✅ python-devops-cicd-expert (needs expansion to multi-language)
- ✅ python-performance-expert
- ✅ python-ml-data-expert

---

### New Agents Needed: 12

### Critical Priority (Create First) - 7 Agents

These agents fill critical gaps in the SDLC and should be created immediately:

#### 1. business-analyst
- **Phase**: 1 (Discovery & Requirements)
- **Criticality**: CRITICAL
- **Why**: No existing agent handles PRD parsing and requirements refinement
- **Impact**: Ensures clear requirements before any development
- **Effort**: Medium
- **Dependencies**: None

#### 2. database-architect
- **Phase**: 2 (Architecture & Planning)
- **Criticality**: CRITICAL
- **Why**: Database design is fundamental, no existing agent covers this
- **Impact**: Prevents database design issues that are costly to fix later
- **Effort**: Medium
- **Dependencies**: None

#### 3. integration-tester
- **Phase**: 4 (Integration & Testing)
- **Criticality**: CRITICAL
- **Why**: E2E testing is essential, existing testing-expert is unit/integration only
- **Impact**: Catches integration bugs before production
- **Effort**: Medium
- **Dependencies**: Requires existing testing frameworks

#### 4. release-manager
- **Phase**: 5 (Deployment Preparation)
- **Criticality**: CRITICAL
- **Why**: No orchestration for deployment planning and execution
- **Impact**: Ensures safe, documented deployments
- **Effort**: Medium
- **Dependencies**: devops-cicd-expert

#### 5. security-auditor
- **Phase**: 5 (Deployment Preparation)
- **Criticality**: CRITICAL
- **Why**: Comprehensive security audit beyond code-level security-expert
- **Impact**: Prevents security breaches in production
- **Effort**: High
- **Dependencies**: security-expert (for code-level findings)

#### 6. monitoring-specialist
- **Phase**: 6 (Deployment & Launch), 7 (Post-Launch)
- **Criticality**: CRITICAL
- **Why**: Production monitoring is non-negotiable
- **Impact**: Enables fast incident response and prevents outages
- **Effort**: High
- **Dependencies**: Infrastructure (Prometheus, Grafana, etc.)

#### 7. incident-responder
- **Phase**: 7 (Post-Launch)
- **Criticality**: CRITICAL
- **Why**: Production issues require dedicated triage and resolution
- **Impact**: Minimizes downtime and user impact
- **Effort**: Medium
- **Dependencies**: monitoring-specialist

---

### High Priority (Create Soon) - 3 Agents

Important for complete workflow, but can start without them:

#### 8. ux-ui-designer
- **Phase**: 1 (Discovery & Requirements)
- **Criticality**: HIGH
- **Why**: UX design improves product quality significantly
- **Impact**: Better user experience, fewer redesigns
- **Effort**: Medium
- **Dependencies**: None
- **Can Defer**: User can provide designs initially

#### 9. integration-engineer
- **Phase**: 3 (Implementation)
- **Criticality**: HIGH
- **Why**: Third-party integrations are common (OAuth, payments, email)
- **Impact**: Standardizes integration patterns, prevents security issues
- **Effort**: Medium
- **Dependencies**: None
- **Can Defer**: Backend developers can handle initially

#### 10. qa-coordinator
- **Phase**: 4 (Integration & Testing)
- **Criticality**: HIGH
- **Why**: Orchestrates testing strategy across multiple test types
- **Impact**: Comprehensive quality assurance
- **Effort**: Low
- **Dependencies**: testing-expert, integration-tester
- **Can Defer**: tech-lead can coordinate initially

---

### Medium Priority (Nice to Have) - 2 Agents

Enhance workflow but not strictly necessary:

#### 11. sprint-planner
- **Phase**: 2 (Architecture & Planning)
- **Criticality**: MEDIUM
- **Why**: Agile planning and estimation
- **Impact**: Better sprint planning and velocity tracking
- **Effort**: Low
- **Dependencies**: tech-lead-orchestrator
- **Can Defer**: tech-lead can handle sprint planning initially

#### 12. analytics-specialist
- **Phase**: 7 (Post-Launch)
- **Criticality**: MEDIUM
- **Why**: Product analytics for data-driven decisions
- **Impact**: Better feature prioritization
- **Effort**: Medium
- **Dependencies**: Analytics tools (GA, Mixpanel)
- **Can Defer**: Can start with basic metrics, add later

---

### Low Priority (Optional) - 1 Agent

Optional enhancement for mature workflows:

#### 13. product-analyst
- **Phase**: 7 (Post-Launch)
- **Criticality**: LOW
- **Why**: Product roadmap and feature analysis
- **Impact**: Strategic product decisions
- **Effort**: Medium
- **Dependencies**: analytics-specialist
- **Can Defer**: User/product owner can handle initially

---

## Multi-Language Expansions Needed

Several existing Python-focused agents need expansion to support multiple languages:

### Expand to Multi-Language - 3 Agents

#### A. testing-expert (currently python-testing-expert)
- **Current**: Python (pytest)
- **Add**: JavaScript/TypeScript (Jest, Vitest), Ruby (RSpec), PHP (PHPUnit)
- **Priority**: HIGH
- **Effort**: Medium per language

#### B. security-expert (currently python-security-expert)
- **Current**: Python security patterns
- **Add**: JavaScript, Ruby, PHP, Go security patterns
- **Priority**: HIGH
- **Effort**: High per language (security is complex)

#### C. devops-cicd-expert (currently python-devops-cicd-expert)
- **Current**: Python deployment
- **Add**: Node.js, Ruby, PHP, Go, Java deployment patterns
- **Priority**: HIGH
- **Effort**: Medium per language

---

## Implementation Roadmap

### Week 1-2: Critical Foundation
1. ✅ **business-analyst** (Phase 1 essential)
2. ✅ **database-architect** (Phase 2 essential)
3. ✅ **integration-tester** (Phase 4 essential)

**Why**: These three enable the core workflow from requirements through testing

---

### Week 3-4: Deployment Readiness
4. ✅ **release-manager** (Phase 5 essential)
5. ✅ **security-auditor** (Phase 5 essential)
6. ✅ **monitoring-specialist** (Phase 6-7 essential)

**Why**: Cannot safely deploy to production without these

---

### Week 5-6: Production Operations
7. ✅ **incident-responder** (Phase 7 essential)
8. ✅ **ux-ui-designer** (Phase 1 quality improvement)
9. ✅ **integration-engineer** (Phase 3 third-party integrations)

**Why**: Production operations and UX quality

---

### Week 7-8: Multi-Language Support
10. ✅ Expand **testing-expert** to JavaScript/TypeScript
11. ✅ Expand **security-expert** to JavaScript/TypeScript
12. ✅ Expand **devops-cicd-expert** to Node.js

**Why**: Support non-Python projects

---

### Week 9-10: Workflow Enhancements
13. ✅ **qa-coordinator** (testing orchestration)
14. ✅ **sprint-planner** (agile planning)
15. ✅ **analytics-specialist** (product analytics)

**Why**: Complete the full workflow with planning and analytics

---

### Week 11+: Optional & Additional Languages
16. ✅ **product-analyst** (strategic product decisions)
17. ✅ Expand agents to Ruby, PHP, Go, Java

**Why**: Mature workflow and comprehensive language support

---

## Dependency Map

Shows which agents depend on others:

```
business-analyst
   └─→ ux-ui-designer (uses requirements)
         └─→ api-architect (uses designs)

database-architect
   └─→ ORM experts (implement schema)
         └─→ Backend experts (use models)

integration-tester
   └─→ qa-coordinator (orchestrates testing)

devops-cicd-expert
   └─→ release-manager (uses CI/CD pipeline)
         └─→ monitoring-specialist (uses infrastructure)
               └─→ incident-responder (uses monitoring)

security-auditor
   └─→ release-manager (blocks release if critical issues)

analytics-specialist
   └─→ product-analyst (uses analytics data)
```

---

## Resource Requirements

### Per Agent Creation

**Time Investment**:
- Simple agent (e.g., sprint-planner): 4-6 hours
- Medium agent (e.g., database-architect): 8-12 hours
- Complex agent (e.g., security-auditor): 16-24 hours

**Components Per Agent**:
1. Agent definition file (.md) - 2-4 hours
2. System prompt engineering - 2-4 hours
3. Example scenarios (3-5 examples) - 2-4 hours
4. Testing and refinement - 2-6 hours
5. Documentation - 1-2 hours

**Total for All New Agents**:
- 12 new agents × 10 hours avg = 120 hours
- 3 multi-language expansions × 8 hours = 24 hours
- **Total**: ~144 hours (~3.5 weeks for one person)

---

## Quick Start: Minimum Viable Agent Set

If you need to start immediately with minimal agents, create these 5:

1. **business-analyst** - Requirements clarity
2. **database-architect** - Database design
3. **release-manager** - Deployment safety
4. **monitoring-specialist** - Production health
5. **incident-responder** - Issue resolution

**With these 5 + existing 20 agents, you can run the complete SDLC**
(Other roles can be handled by tech-lead-orchestrator or users initially)

---

## Agent Creation Templates

Refer to:
- `templates/agent-template.md` - Basic agent structure
- `docs/creating-agents.md` - Detailed guide
- Existing agents for examples

---

## Success Criteria

After creating all agents, you should be able to:
- ✅ Take a PRD and deliver production-ready software
- ✅ Handle all 7 SDLC phases with specialized agents
- ✅ Support multiple programming languages and frameworks
- ✅ Maintain production systems with monitoring and incident response
- ✅ Iterate on features with continuous improvement

---

## Summary Table

| # | Agent Name | Priority | Phase | Effort | Dependencies |
|---|------------|----------|-------|--------|--------------|
| 1 | business-analyst | CRITICAL | 1 | Medium | None |
| 2 | database-architect | CRITICAL | 2 | Medium | None |
| 3 | integration-tester | CRITICAL | 4 | Medium | testing-expert |
| 4 | release-manager | CRITICAL | 5 | Medium | devops-cicd-expert |
| 5 | security-auditor | CRITICAL | 5 | High | security-expert |
| 6 | monitoring-specialist | CRITICAL | 6-7 | High | Infrastructure |
| 7 | incident-responder | CRITICAL | 7 | Medium | monitoring-specialist |
| 8 | ux-ui-designer | HIGH | 1 | Medium | None |
| 9 | integration-engineer | HIGH | 3 | Medium | None |
| 10 | qa-coordinator | HIGH | 4 | Low | testing agents |
| 11 | sprint-planner | MEDIUM | 2 | Low | tech-lead |
| 12 | analytics-specialist | MEDIUM | 7 | Medium | Analytics tools |
| 13 | product-analyst | LOW | 7 | Medium | analytics-specialist |
| A | testing-expert (expand) | HIGH | 3-4 | Medium | N/A |
| B | security-expert (expand) | HIGH | 3,5 | High | N/A |
| C | devops-cicd-expert (expand) | HIGH | 5-6 | Medium | N/A |

**Total New**: 13 agents + 3 expansions = 16 tasks