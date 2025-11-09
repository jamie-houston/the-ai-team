# Phase 5: Deployment Preparation

## Overview

**Duration**: 2-3 days
**Objective**: Prepare application for production deployment
**Approval Gate**: ✅ User approves deployment to production
**Prerequisites**: Phase 4 completed with all quality gates passed

This phase ensures the application is production-ready with proper CI/CD, infrastructure, and security measures in place.

---

## Agents in This Phase

### 1. devops-cicd-expert

**Status**: ⚠️ EXISTING (Python-focused, needs multi-language expansion)
**Role**: CI/CD pipeline and infrastructure configuration

#### Responsibilities

- CI/CD pipeline configuration (GitHub Actions, GitLab CI, Jenkins)
- Docker containerization and optimization
- Kubernetes deployment manifests
- Infrastructure as Code (Terraform, CloudFormation)
- Environment configuration management
- Secrets management (Vault, AWS Secrets Manager)
- Build optimization
- Container registry setup

#### Input

- Application codebase
- Deployment requirements
- Infrastructure preferences (AWS, GCP, Azure, on-prem)
- Environment specifications (staging, production)

#### Output

**CI/CD Pipeline (GitHub Actions Example):**
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt

      - name: Run tests
        run: |
          pytest --cov=. --cov-report=xml

      - name: Upload coverage
        uses: codecov/codecov-action@v3

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run linters
        run: |
          flake8 .
          black --check .
          mypy .

  build:
    needs: [test, lint]
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix={{branch}}-
            type=ref,event=branch
            type=semver,pattern={{version}}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging

    steps:
      - uses: actions/checkout@v4

      - name: Configure kubectl
        uses: azure/k8s-set-context@v3
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBE_CONFIG_STAGING }}

      - name: Deploy to Kubernetes (Staging)
        run: |
          kubectl apply -f k8s/staging/
          kubectl rollout status deployment/user-management -n staging

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Configure kubectl
        uses: azure/k8s-set-context@v3
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBE_CONFIG_PROD }}

      - name: Deploy to Kubernetes (Production)
        run: |
          kubectl apply -f k8s/production/
          kubectl rollout status deployment/user-management -n production

      - name: Run smoke tests
        run: |
          ./scripts/smoke-test.sh https://api.example.com
```

**Dockerfile (Multi-stage build):**
```dockerfile
# Build stage
FROM python:3.11-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim

WORKDIR /app

# Copy Python dependencies from builder
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY . .

# Make sure scripts are executable
RUN chmod +x scripts/*.sh

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Add local bin to PATH
ENV PATH=/root/.local/bin:$PATH

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD python scripts/healthcheck.py || exit 1

# Run application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "app:app"]
```

**Kubernetes Deployment:**
```yaml
# k8s/production/deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-management
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user-management
  template:
    metadata:
      labels:
        app: user-management
    spec:
      containers:
      - name: app
        image: ghcr.io/org/user-management:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: jwt-secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: user-management
  namespace: production
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8000
  selector:
    app: user-management

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: user-management
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: user-management
            port:
              number: 80
```

---

### 2. release-manager

**Status**: 🔴 NEW - Priority: CRITICAL
**Role**: Release planning and deployment orchestration

#### Responsibilities

- Create release plans
- Define deployment strategy (blue-green, canary, rolling)
- Develop rollback procedures
- Feature flag management
- Generate release notes
- Coordinate stakeholder communication
- Execute smoke tests in production
- Post-deployment verification

#### Input

- Tested and approved build
- Quality metrics from Phase 4
- Infrastructure configuration
- Release requirements

#### Output

```
## Release Plan

### Release Information

**Version**: v1.0.0
**Release Date**: 2025-11-15 10:00 AM PST
**Release Type**: Major Release (User Management System)
**Deployment Strategy**: Rolling Deployment
**Estimated Downtime**: Zero (rolling deployment)

---

### Pre-Deployment Checklist

- [x] All quality gates passed
- [x] Security audit completed
- [x] Performance testing completed
- [x] Database migrations tested in staging
- [x] Rollback plan documented
- [x] Stakeholders notified
- [x] Monitoring dashboards configured
- [x] Alerts configured
- [x] Backup completed
- [ ] Final approval from Product Owner

---

### Deployment Strategy: Rolling Deployment

**Why Rolling?**
- Zero downtime
- Gradual rollout allows early detection of issues
- Easy rollback if problems occur

**Deployment Steps**:
1. Deploy to 1 pod (33% of traffic)
2. Monitor for 10 minutes
3. If healthy, deploy to 2nd pod (66% of traffic)
4. Monitor for 10 minutes
5. If healthy, deploy to 3rd pod (100% of traffic)
6. Final smoke tests
7. Mark deployment complete

**Traffic Routing**:
```
Step 1: Old(67%) + New(33%)
Step 2: Old(33%) + New(67%)
Step 3: New(100%)
```

---

### Database Migration Plan

**Migrations to Apply**:
1. `0001_initial.py` - Create users table
2. `0002_roles.py` - Create roles and permissions tables
3. `0003_user_roles.py` - Create user-role association table

**Migration Strategy**:
- **Backward Compatible**: Migrations are additive only (no breaking changes)
- **Execution**: Run migrations before deploying new code
- **Rollback**: Each migration has down() method

**Execution Steps**:
```bash
# 1. Backup database
pg_dump production_db > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Run migrations
python manage.py migrate --no-input

# 3. Verify migrations applied
python manage.py showmigrations

# 4. If issues, rollback
python manage.py migrate users 0002  # Roll back to previous version
```

---

### Rollback Plan

**Rollback Trigger Conditions**:
- Error rate > 5%
- Response time > 1000ms
- Critical bug discovered
- Data corruption detected

**Rollback Steps** (15-minute RTO):
```
1. Identify issue (2 min)
2. Decide to rollback (1 min)
3. Execute rollback command (2 min):
   kubectl rollout undo deployment/user-management -n production
4. Verify old version running (5 min)
5. Test smoke tests (5 min)
6. Notify stakeholders
```

**Database Rollback**:
```bash
# If migration rollback needed
python manage.py migrate users 0002
```

---

### Feature Flags

**Enabled Features**:
- `user_registration`: ON
- `email_verification`: ON
- `oauth_google`: OFF (deploy code, enable later)
- `two_factor_auth`: OFF (future feature)

**Flag Management**:
- Use LaunchDarkly / Unleash for remote flag control
- Allows enabling features without redeployment

---

### Release Notes

**Version 1.0.0 - User Management System**

**New Features**:
- User registration with email verification
- Secure login with JWT authentication
- Role-based access control (Admin, Editor, Viewer)
- User profile management
- Admin dashboard for user management

**API Endpoints Added**:
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `GET /api/v1/users` - List users (paginated)
- `GET /api/v1/users/:id` - Get user details
- `PUT /api/v1/users/:id` - Update user profile
- `POST /api/v1/users/:id/roles` - Assign role (admin only)

**Security**:
- Passwords hashed with bcrypt
- JWT tokens with 15-minute expiry
- Rate limiting on auth endpoints
- HTTPS enforced

**Performance**:
- Average response time: 124ms
- 95th percentile: 287ms
- Supports 1000 concurrent users

**Known Issues**:
- Safari responsive layout issue on viewport < 768px (will fix in v1.0.1)

---

### Smoke Test Checklist

Post-deployment verification (run in production):

- [ ] Health check endpoint returns 200 OK
- [ ] User can register successfully
- [ ] User can login and receive JWT token
- [ ] User can update profile
- [ ] Admin can assign roles
- [ ] Permission checks enforced correctly
- [ ] Database migrations applied successfully
- [ ] No error spikes in monitoring
- [ ] Response times within acceptable range

---

### Communication Plan

**T-24 hours**: Email to stakeholders
  - Release scheduled for Nov 15, 10:00 AM
  - Expected impact: None (zero downtime)

**T-1 hour**: Slack notification
  - Deployment starting soon
  - War room channel: #release-v1

**T+0**: Deployment begins
  - Status updates every 10 minutes in #release-v1

**T+1 hour**: Post-deployment report
  - Summary of deployment
  - Smoke test results
  - Any issues encountered

---

### Go/No-Go Decision

**Criteria for GO**:
- [x] All tests passing
- [x] Security audit complete
- [x] Rollback plan ready
- [x] Database backup complete
- [x] Monitoring configured
- [ ] Product Owner approval

**Decision**: ⏳ PENDING (awaiting final approval)
```

---

### 3. security-auditor

**Status**: 🔴 NEW - Priority: CRITICAL
**Role**: Comprehensive security assessment

#### Responsibilities

- Penetration testing
- Vulnerability scanning (OWASP ZAP, Burp Suite, Snyk)
- Dependency security audit
- Compliance verification (GDPR, HIPAA, SOC2)
- Security headers configuration
- SSL/TLS configuration review
- Infrastructure security assessment

#### Input

- Complete application (frontend + backend)
- Infrastructure configuration
- Compliance requirements

#### Output

```
## Security Audit Report

**Date**: 2025-11-08
**Application**: User Management System v1.0.0
**Auditor**: security-auditor (AI Agent)

---

### Executive Summary

**Overall Security Rating**: B+ (Good)
- Critical Issues: 0
- High Priority: 2
- Medium Priority: 4
- Low Priority: 3

**Recommendation**: Fix high-priority issues before production deployment.

---

### Vulnerability Scan Results

#### OWASP Top 10 Assessment

| Risk | Status | Findings |
|------|--------|----------|
| A01: Broken Access Control | ✅ PASS | RBAC properly implemented |
| A02: Cryptographic Failures | ⚠️ WARN | See HIGH-002 below |
| A03: Injection | ✅ PASS | ORM used, no raw SQL |
| A04: Insecure Design | ✅ PASS | Security by design |
| A05: Security Misconfiguration | ⚠️ WARN | See HIGH-001 below |
| A06: Vulnerable Components | ✅ PASS | All dependencies up-to-date |
| A07: Authentication Failures | ✅ PASS | Strong auth implementation |
| A08: Data Integrity Failures | ✅ PASS | Input validation present |
| A09: Logging Failures | ⚠️ WARN | See MED-001 below |
| A10: SSRF | ✅ PASS | No external URL fetching |

---

### Critical Issues

**None Found** ✅

---

### High Priority Issues (Must Fix)

**HIGH-001: Missing Security Headers**
- **Severity**: High
- **Description**: Several security headers not configured
- **Impact**: Vulnerable to clickjacking, MIME sniffing
- **Missing Headers**:
  - `X-Frame-Options: DENY`
  - `X-Content-Type-Options: nosniff`
  - `Strict-Transport-Security: max-age=31536000`
  - `Content-Security-Policy`
- **Remediation**:
```python
# Django middleware
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_HSTS_SECONDS = 31536000
CSP_DEFAULT_SRC = ("'self'",)
```

**HIGH-002: JWT Token Not Invalidated on Logout**
- **Severity**: High
- **Description**: JWT tokens remain valid after logout
- **Impact**: Stolen tokens can be used until expiry
- **Remediation**: Implement token blacklist or use refresh token rotation

---

### Medium Priority Issues

**MED-001: Insufficient Logging**
- **Severity**: Medium
- **Description**: Login failures not logged
- **Impact**: Difficult to detect brute-force attacks
- **Remediation**: Log all auth failures with IP address

**MED-002: No Rate Limiting on Registration**
- **Severity**: Medium
- **Description**: Registration endpoint not rate-limited
- **Impact**: Account enumeration, spam registrations
- **Remediation**: Add rate limit (3 requests/hour per IP)

**MED-003: Password Reset Token Not Expiring**
- **Severity**: Medium
- **Description**: Reset tokens valid indefinitely
- **Impact**: Old reset links can be exploited
- **Remediation**: Add 1-hour expiry to reset tokens

**MED-004: No CAPTCHA on Public Forms**
- **Severity**: Medium
- **Description**: No bot protection
- **Impact**: Automated abuse possible
- **Remediation**: Add reCAPTCHA v3

---

### Low Priority Issues

**LOW-001: Verbose Error Messages**
- **Severity**: Low
- **Description**: Stack traces visible in some error responses
- **Impact**: Information leakage
- **Remediation**: Generic error messages in production

**LOW-002: Session Cookies Without SameSite**
- **Severity**: Low
- **Description**: Cookies missing SameSite attribute
- **Impact**: CSRF risk (mitigated by CSRF tokens)
- **Remediation**: Set `SameSite=Lax`

**LOW-003: Missing Security.txt**
- **Severity**: Low
- **Description**: No security.txt for responsible disclosure
- **Impact**: Researchers may not know how to report issues
- **Remediation**: Add `/.well-known/security.txt`

---

### Dependency Audit

**Vulnerable Dependencies**: None
**Outdated Dependencies**: 2 (non-security updates available)

```
django: 4.2.7 → 4.2.8 (bug fixes)
djangorestframework: 3.14.0 → 3.15.0 (features)
```

**Recommendation**: Update to latest stable versions.

---

### SSL/TLS Configuration

**Grade**: A

- ✅ TLS 1.3 enabled
- ✅ Strong cipher suites only
- ✅ Certificate valid and trusted
- ✅ HSTS enabled
- ✅ Certificate transparency logs

---

### Compliance Assessment

**GDPR Compliance**:
- ✅ User data deletion implemented
- ✅ Data export functionality (API available)
- ✅ Privacy policy displayed
- ⚠️ Cookie consent banner missing (if using analytics)

**General Data Protection**:
- ✅ Passwords hashed (bcrypt)
- ✅ PII encrypted in transit (HTTPS)
- ⚠️ PII encryption at rest (database) - consider for v1.1

---

### Penetration Testing Results

**Manual Tests Conducted**:
1. SQL Injection attempts: ✅ PASS (ORM prevents)
2. XSS attempts: ✅ PASS (Input sanitized)
3. CSRF: ✅ PASS (Tokens validated)
4. Auth bypass: ✅ PASS (Proper checks)
5. Privilege escalation: ✅ PASS (RBAC enforced)

**Automated Scan (OWASP ZAP)**:
- Alerts: 9 (0 high, 2 medium, 7 low)
- False positives: 4
- Legitimate issues: 5 (documented above)

---

### Recommendations

**Before Production Deployment**:
1. Fix HIGH-001 (security headers) - 30 minutes
2. Fix HIGH-002 (JWT blacklist) - 2 hours
3. Update dependencies - 15 minutes

**Post-Deployment (v1.0.1)**:
4. Fix all medium-priority issues
5. Add CAPTCHA
6. Implement at-rest encryption for PII

**Security Monitoring**:
- Set up alerts for auth failures
- Monitor for unusual traffic patterns
- Regular dependency audits (monthly)
```

---

## Phase 5 Workflow

```
Day 1: Infrastructure & CI/CD
├─ devops-cicd-expert: Create CI/CD pipeline
│  ├─ GitHub Actions workflow
│  ├─ Dockerfile (multi-stage)
│  ├─ Kubernetes manifests
│  └─ Infrastructure as Code (Terraform)
│
└─ devops-cicd-expert: Configure environments
   ├─ Staging environment
   ├─ Production environment
   └─ Secrets management

Day 2: Security Audit
├─ security-auditor: Vulnerability scanning
├─ security-auditor: Penetration testing
├─ security-auditor: Dependency audit
└─ security-auditor: Compliance check

Day 3: Release Planning
├─ release-manager: Create release plan
├─ release-manager: Define deployment strategy
├─ release-manager: Document rollback procedure
├─ release-manager: Generate release notes
└─ release-manager: Prepare smoke tests

Day 4: Fix Security Issues & Final Prep
├─ Developers: Fix high-priority security issues
├─ security-auditor: Re-scan after fixes
├─ release-manager: Final go/no-go decision
└─ APPROVAL GATE 3: User approves deployment
```

---

## Deliverables Checklist

- [ ] **CI/CD Pipeline**
  - [ ] Automated testing in pipeline
  - [ ] Container build and push
  - [ ] Deployment automation
  - [ ] Rollback capability

- [ ] **Infrastructure**
  - [ ] Kubernetes manifests created
  - [ ] Infrastructure as Code (Terraform)
  - [ ] Secrets properly managed
  - [ ] Monitoring configured

- [ ] **Security Audit**
  - [ ] Zero critical vulnerabilities
  - [ ] High-priority issues fixed
  - [ ] Compliance requirements met
  - [ ] SSL/TLS properly configured

- [ ] **Release Plan**
  - [ ] Deployment strategy defined
  - [ ] Rollback plan documented
  - [ ] Release notes generated
  - [ ] Smoke tests prepared

- [ ] **Approvals**
  - [ ] Security audit approved
  - [ ] Product owner sign-off
  - [ ] User approval for deployment

---

## Next Phase

Once approved, proceed to [Phase 6: Deployment & Launch](./phase-6-deployment.md)