# The A.I. Team

*I love it when a plan compiles together.*

A team of 75 specialized AI agents for [Claude Code](https://claude.ai/code) that work together to build, test, review, and ship software across the entire development lifecycle.

## What This Is

Instead of one generalist AI, you get a coordinated team of specialists — a tech lead that routes tasks, framework experts that write idiomatic code, reviewers that catch bugs, and architects that design systems. Each agent has deep domain knowledge and knows how to hand off work to the next specialist.

## What It Covers

| Area | What You Get |
|------|-------------|
| **Planning & Requirements** | PRD analysis, sprint planning, business analysis, UX/UI design |
| **Architecture & Design** | Database design, API architecture, system design |
| **Implementation** | Framework-specific experts for Python, Django, FastAPI, Rails, Laravel, React, Vue, Next.js, Node.js, .NET, Android/Kotlin |
| **Quality & Testing** | Code review, security audits, QA coordination, integration testing, performance optimization |
| **Operations** | Incident response, monitoring, release management, DevOps/CI-CD |
| **Documentation** | Technical docs, README generation, code archaeology for legacy codebases |

## Quick Start

### Prerequisites
- [Claude Code CLI](https://claude.ai/code) installed and authenticated

### 1. Clone and Link

```bash
git clone https://github.com/jamie-houston/the-ai-team.git
cd the-ai-team
./link.sh
```

This symlinks all agents and commands to `~/.claude/` so they're globally available and auto-update when you pull.

### 2. Verify

```bash
claude /agents
```

### 3. Start Using

Point the tech lead at any task and it will route to the right specialists:

```bash
claude "use @agent-tech-lead-orchestrator to build a user authentication system"
```

Or call agents directly:

```bash
claude "use @agent-code-reviewer to review my recent changes"
claude "use @agent-database-architect to design a schema for user management"
```

To unlink later: `./unlink.sh`

## Agent Roster

### Orchestrators (3)
Coordinate complex multi-step tasks across the team.

- **Tech Lead Orchestrator** — analyzes projects, creates execution plans, routes to the right specialists
- **Project Analyst** — detects your technology stack for intelligent agent routing
- **Team Configurator** — configures optimal agent mappings for your project in CLAUDE.md

### Core Team (18)
Cross-cutting specialists that work with any stack.

Analytics Specialist, Business Analyst, Code Archaeologist, Code Reviewer, Database Architect, Documentation Specialist, Incident Responder, Integration Engineer, Integration Tester, Monitoring Specialist, Performance Optimizer, QA Coordinator, Refactoring Expert, Release Manager, Requirements Verifier, Security Auditor, Sprint Planner, UX/UI Designer

### Framework Specialists (47)

| Stack | Agents | Coverage |
|-------|--------|----------|
| **Python** | 9 | Core Python, Django, FastAPI, ML/Data, DevOps, Performance, Testing, Security, Web Scraping |
| **.NET** | 11 | Blazor, Console, Debug, EF Core, Razor, Refactor, Review, Scaffold, SQL, Testing, Web API |
| **Next.js** | 7 | API, Auth, Database, Pages, Review, Scaffold, Testing |
| **Node.js** | 6 | API, Database, Debug, Review, Scaffold, Testing |
| **Django** | 3 | Backend, API, ORM |
| **Rails** | 3 | Backend, API, ActiveRecord |
| **Vue** | 3 | Components, Nuxt, State Management |
| **React** | 2 | Components, Next.js |
| **Laravel** | 2 | Backend, Eloquent |
| **Android** | 1 | Kotlin |

### Universal Experts (7)
Framework-agnostic fallbacks when no specialist exists.

API Architect, Backend Developer, Frontend Developer, Tailwind CSS Expert, PRD Analyst, Git Helper, Orchestrator

## Slash Commands (31)

Quick-access commands for common workflows — type `/command-name` in Claude Code.

Includes scaffolding, testing, debugging, code review, refactoring, database, API development, and more across .NET, Node.js, and Next.js stacks. Run `claude /commands` to see the full list.

## Work Loop

`work-loop.sh` cycles through a project's queued work — planning stories, implementing them, deploying — without starting a session per task:

```bash
./work-loop.sh ~/src/jamie-houston/<project> [--max N] [--budget USD]
```

Each iteration is a fresh headless `claude -p "/project-context auto"` session that does exactly one step, writes status to the Obsidian vault, and exits with a JSON handoff the loop parses. Fresh minimal sessions are the cheap shape: a long-lived looping session re-reads its ever-growing context every turn and re-writes all of it at 1.25x after any pause past the 5-minute cache TTL, while here nothing idles between iterations and all inter-task state lives in the vault. The loop stops on its own at `needs-decision` steps, blockers, permission denials, or an empty queue; stop it yourself with `touch <repo>/.work-loop-stop`. Details in `skills/project-context/references/headless.md`.

## How It Works

The tech lead orchestrator is the entry point for complex tasks. It:

1. **Analyzes** your request and your project's tech stack
2. **Routes** to the right specialist agents (e.g., Django project gets Django experts, not Rails)
3. **Coordinates** handoffs between agents with structured context passing
4. **Presents** a plan for your approval before execution

Agents can't call each other directly — Claude Code's main agent coordinates everything based on the tech lead's routing map.

## Docs

- [Installation Guide](INSTALLATION.md)
- [Creating Custom Agents](docs/creating-agents.md)
- [Best Practices](docs/best-practices.md)
- [SDLC Workflow Guide](docs/workflows/README.md)
- [.NET Workflow](docs/dotnet-workflow.md) | [Node.js Workflow](docs/nodejs-workflow.md) | [Next.js Workflow](docs/nextjs-workflow.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

- [Report issues](https://github.com/jamie-houston/the-ai-team/issues)
- [Discussions](https://github.com/jamie-houston/the-ai-team/discussions)

## License

MIT — see [LICENSE](LICENSE).
