# Awesome Claude Agents - AI Development Team 🚀

**Supercharge Claude Code with a team of specialized AI agents** that work together to build complete features, debug complex issues, and handle any technology stack with expert-level knowledge.

## ⚠️ Important Notice

**This project is experimental and token-intensive.** I'm actively testing these agents with Claude subscription - expect high token consumption during complex workflows. Multi-agent orchestration can consume 10-50k tokens per complex feature. Use with caution and monitor your usage.

## 🚀 Quick Start (3 Minutes)

### Prerequisites
- **Claude Code CLI** installed and authenticated
- **Claude subscription** - required for intensive agent workflows
- Active project directory with your codebase
- **Optional**: [Context7 MCP](docs/dependencies.md) for enhanced documentation access

### 1. Install the Agents

Clone the repository:
```bash
git clone https://github.com/jamie-houston/awesome-claude-agents.git
cd awesome-claude-agents
```

#### Option A: Symlink (Recommended - auto-updates)

**macOS/Linux:**
```bash
# Run the linking script
./link.sh
```

This will symlink all agent directories to `~/.claude/agents/` and command files to `~/.claude/commands/` making them globally available. The agents and commands will auto-update when you pull new changes from the repository.

To unlink later:
```bash
./unlink.sh
```

**Windows:**
*Symlink script for Windows coming soon. Use Option B (copy) for now.*

#### Option B: Copy (Static - no auto-updates)
```bash
# Create directories if they don't exist
mkdir -p ~/.claude/agents ~/.claude/commands

# Copy all agents and commands
cp -r agents/* ~/.claude/agents/
cp -r commands/* ~/.claude/commands/
```

### 2. Verify Installation
```bash
claude /agents
# Should show all 61 agents across core, orchestrators, specialized, and universal categories.
```

### 3. Initialize Your Project
**Navigate** to your **project directory** and run the following command to configure your AI team:

```bash
claude "use @agent-team-configurator and optimize my project to best use the available subagents."
```

### 4. Start Building
```bash
claude "use @agent-tech-lead-orchestrator and build a user authentication system"
```

Your AI team will automatically detect your stack and use the right specialists!

## 🎯 How Auto-Configuration Works

The @agent-team-configurator automatically sets up your perfect AI development team. When invoked, it:

1. **Locates CLAUDE.md** - Finds existing project configuration and preserves all your custom content outside the "AI Team Configuration" section
2. **Detects Technology Stack** - Inspects package.json, composer.json, requirements.txt, go.mod, Gemfile, and build configs to understand your project
3. **Discovers Available Agents** - Scans ~/.claude/agents/ and .claude/ folders, building a capability table of all available specialists
4. **Selects Specialists** - Prefers framework-specific agents over universal ones, always includes @agent-code-reviewer and @agent-performance-optimizer for quality assurance
5. **Updates CLAUDE.md** - Creates a timestamped "AI Team Configuration" section with your detected stack and a Task|Agent|Notes mapping table
6. **Provides Usage Guidance** - Shows you the detected stack, selected agents, and gives sample commands to start building


## 👥 Meet Your AI Development Team

### 🎭 Orchestrators (3 agents)
- **[Tech Lead Orchestrator](agents/orchestrators/tech-lead-orchestrator.md)** - Senior technical lead who analyzes complex projects and coordinates multi-step development tasks
- **[Project Analyst](agents/orchestrators/project-analyst.md)** - Technology stack detection specialist who enables intelligent agent routing
- **[Team Configurator](agents/orchestrators/team-configurator.md)** - AI team setup expert who detects your stack and configures optimal agent mappings

### 💼 Framework Specialists (34 agents)
- **Python (9 agents)**
  - **[Python Expert](agents/specialized/python/python-expert.md)** - Modern Python 3.12+ development, APIs, and project architecture
  - **[Django Expert](agents/specialized/python/django-expert.md)** - Comprehensive Django 5.0+ web development and ecosystem
  - **[FastAPI Expert](agents/specialized/python/fastapi-expert.md)** - High-performance async APIs with FastAPI and Pydantic V2
  - **[ML/Data Expert](agents/specialized/python/ml-data-expert.md)** - Machine learning, data science, and AI with modern Python stack
  - **[DevOps/CI-CD Expert](agents/specialized/python/devops-cicd-expert.md)** - Python DevOps, deployment automation, and infrastructure
  - **[Performance Expert](agents/specialized/python/performance-expert.md)** - Python optimization, profiling, and concurrent programming
  - **[Testing Expert](agents/specialized/python/testing-expert.md)** - Comprehensive testing strategies and test automation
  - **[Security Expert](agents/specialized/python/security-expert.md)** - Python security, cryptography, and vulnerability assessment
  - **[Web Scraping Expert](agents/specialized/python/web-scraping-expert.md)** - Data extraction, automation, and async web crawling
- **Laravel (2 agents)**
  - **[Backend Expert](agents/specialized/laravel/laravel-backend-expert.md)** - Comprehensive Laravel development with MVC, services, and Eloquent patterns
  - **[Eloquent Expert](agents/specialized/laravel/laravel-eloquent-expert.md)** - Advanced ORM optimization, complex queries, and database performance
- **Django (3 agents)**
  - **[Backend Expert](agents/specialized/django/django-backend-expert.md)** - Models, views, services following current Django conventions
  - **[API Developer](agents/specialized/django/django-api-developer.md)** - Django REST Framework and GraphQL implementations
  - **[ORM Expert](agents/specialized/django/django-orm-expert.md)** - Query optimization and database performance for Django applications
- **Rails (3 agents)**
  - **[Backend Expert](agents/specialized/rails/rails-backend-expert.md)** - Full-stack Rails development following conventions
  - **[API Developer](agents/specialized/rails/rails-api-developer.md)** - RESTful APIs and GraphQL with Rails patterns
  - **[ActiveRecord Expert](agents/specialized/rails/rails-activerecord-expert.md)** - Complex queries and database optimization
- **React (2 agents)**
  - **[Component Architect](agents/specialized/react/react-component-architect.md)** - Modern React patterns, hooks, and component design
  - **[Next.js Expert](agents/specialized/react/react-nextjs-expert.md)** - SSR, SSG, ISR, and full-stack Next.js applications
- **Vue (3 agents)**
  - **[Component Architect](agents/specialized/vue/vue-component-architect.md)** - Vue 3 Composition API and component patterns
  - **[Nuxt Expert](agents/specialized/vue/vue-nuxt-expert.md)** - SSR, SSG, and full-stack Nuxt applications
  - **[State Manager](agents/specialized/vue/vue-state-manager.md)** - Pinia and Vuex state architecture
- **.NET (11 agents)** - [See .NET Workflow Guide](docs/dotnet-workflow.md)
  - **[Blazor Expert](agents/specialized/dotnet/blazor.md)** - Blazor web apps with Server/WASM render modes
  - **[Console Expert](agents/specialized/dotnet/console.md)** - Console application scaffolding and CLI tools
  - **[Debug Expert](agents/specialized/dotnet/debug.md)** - Systematic debugging for .NET applications
  - **[EF Core Expert](agents/specialized/dotnet/efcore.md)** - Entity Framework Core data layer and migrations
  - **[Razor Expert](agents/specialized/dotnet/razor.md)** - Razor Pages UI for MVC-style applications
  - **[Refactor Expert](agents/specialized/dotnet/refactor.md)** - SOLID principles, repository pattern, and DI
  - **[Review Expert](agents/specialized/dotnet/review.md)** - .NET-specific code review and best practices
  - **[Scaffold Expert](agents/specialized/dotnet/scaffold.md)** - .NET project scaffolding and structure
  - **[SQL Expert](agents/specialized/dotnet/sql.md)** - LINQ queries and SQL optimization
  - **[Testing Expert](agents/specialized/dotnet/testing.md)** - xUnit testing and integration tests
  - **[Web API Expert](agents/specialized/dotnet/webapi.md)** - ASP.NET Core Web API development
- **Android/Kotlin (1 agent)**
  - **[Kotlin Expert](agents/specialized/android/kotlin-expert.md)** - Modern Kotlin development, coroutines, and Android patterns

### 🌐 Universal Experts (7 agents)
- **[Backend Developer](agents/universal/backend-developer.md)** - Polyglot backend development across multiple languages and frameworks
- **[Frontend Developer](agents/universal/frontend-developer.md)** - Modern web technologies and responsive design for any framework
- **[API Architect](agents/universal/api-architect.md)** - RESTful design, GraphQL, and framework-agnostic API architecture
- **[Tailwind Frontend Expert](agents/universal/tailwind-css-expert.md)** - Tailwind CSS styling, utility-first development, and responsive components
- **[PRD Analyst](agents/universal/analyze-prd.md)** - Requirements analysis and structured PRD generation
- **[Git Helper](agents/universal/git.md)** - Git workflow expert for clean commit history and best practices
- **[Orchestrator](agents/universal/orchestrate.md)** - Project workflow orchestration and timeline management

### 🔧 Core Team (17 agents)
- **[Analytics Specialist](agents/core/analytics-specialist.md)** - Product analytics, user behavior tracking, and data-driven insights
- **[Business Analyst](agents/core/business-analyst.md)** - PRD analysis, requirements refinement, and user story creation
- **[Code Archaeologist](agents/core/code-archaeologist.md)** - Explores, documents, and analyzes unfamiliar or legacy codebases
- **[Code Reviewer](agents/core/code-reviewer.md)** - Rigorous security-aware reviews with severity-tagged reports
- **[Database Architect](agents/core/database-architect.md)** - Schema design, migration strategies, and database optimization
- **[Documentation Specialist](agents/core/documentation-specialist.md)** - Comprehensive READMEs, API specs, and technical documentation
- **[Incident Responder](agents/core/incident-responder.md)** - Incident triage, debugging, and post-mortem analysis
- **[Integration Engineer](agents/core/integration-engineer.md)** - Third-party API integrations, OAuth, payments, and webhooks
- **[Integration Tester](agents/core/integration-tester.md)** - E2E testing, cross-browser testing, and API contract validation
- **[Monitoring Specialist](agents/core/monitoring-specialist.md)** - Observability, alerting, and production monitoring setup
- **[Performance Optimizer](agents/core/performance-optimizer.md)** - Bottleneck identification and scalable system optimization
- **[QA Coordinator](agents/core/qa-coordinator.md)** - Test strategy, quality gates, and comprehensive QA orchestration
- **[Refactoring Expert](agents/core/refactoring-expert.md)** - Complex refactoring, technical debt reduction, and architectural improvements
- **[Release Manager](agents/core/release-manager.md)** - Release planning, deployment coordination, and rollback procedures
- **[Security Auditor](agents/core/security-auditor.md)** - OWASP Top 10, vulnerability scanning, and compliance verification
- **[Sprint Planner](agents/core/sprint-planner.md)** - Agile planning, story estimation, and velocity tracking
- **[UX/UI Designer](agents/core/ux-ui-designer.md)** - User flows, wireframes, design systems, and component specifications

**Total: 61 specialized agents** working together to build your projects!

[Browse all agents →](agents/)

### ⚡ Slash Commands (18 commands)

Quick-access commands for common workflows. Use these with `/command-name` in Claude Code:

| Command | Description |
|---------|-------------|
| `/analyze-prd` | Convert requirements into a structured PRD |
| `/scaffold` | Create .NET Web API project structure |
| `/scaffold-blazor` | Create Blazor web application structure |
| `/scaffold-console` | Create .NET console application structure |
| `/efcore` | Implement EF Core data layer and models |
| `/webapi` | Create Web API controllers and endpoints |
| `/test` | Add integration tests for API endpoints |
| `/refactor` | Apply SOLID principles (extract repositories, DI) |
| `/debug` | Systematic debugging for .NET issues |
| `/review` | Quick code review before submission |
| `/verify` | Verify implementation against PRD requirements |
| `/git` | Git workflow and commit assistance |
| `/sql` | SQL/LINQ query help and optimization |
| `/orchestrate` | Start the project workflow orchestration |
| `/add-blazor-ui` | Add Blazor UI to existing Web API |
| `/add-razor-ui` | Add Razor Pages UI to existing Web API |
| `/load-data` | Add data import/seeding functionality |
| `/readme` | Generate project README documentation |

[Browse all commands →](commands/)


## 🔥 Why Teams Beat Solo AI

- **Specialized Expertise**: Each agent masters their domain with deep, current knowledge
- **Real Collaboration**: Agents coordinate seamlessly, sharing context and handing off tasks
- **Tailored Solutions**: Get code that matches your exact stack and follows its best practices
- **Parallel Execution**: Multiple specialists work simultaneously for faster delivery

## 📈 The Impact

- **Ship Faster** - Complete features in minutes, not days
- **Better Code Quality** - Every line follows best practices
- **Learn As You Code** - See how experts approach problems
- **Scale Confidently** - Architecture designed for growth

## 📚 Learn More

- [Creating Custom Agents](docs/creating-agents.md) - Build specialists for your needs  
- [Best Practices](docs/best-practices.md) - Get the most from your AI team

## 💬 Join The Community

- ⭐ **Star this repo** to show support
- 🐛 [Report issues](https://github.com/jamie-houston/awesome-claude-agents/issues)
- 💡 [Share ideas](https://github.com/jamie-houston/awesome-claude-agents/discussions)
- 🎉 [Success stories](https://github.com/jamie-houston/awesome-claude-agents/discussions/categories/show-and-tell)

## 📄 License

MIT License - Use freely in your projects!

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=vijaythecoder/awesome-claude-agents&type=Date)](https://www.star-history.com/#vijaythecoder/awesome-claude-agents&Date)
---

<p align="center">
  <strong>Transform Claude Code into an AI development team that ships production-ready features</strong><br>
  <em>Simple setup. Powerful results. Just describe and build.</em>
</p>

<p align="center">
  <a href="https://github.com/jamie-houston/awesome-claude-agents">GitHub</a> •
  <a href="docs/creating-agents.md">Documentation</a> •
  <a href="https://github.com/jamie-houston/awesome-claude-agents/discussions">Community</a>
</p>