# Phase 6: Deployment & Launch

## Overview

**Duration**: 1 day (deployment execution)
**Objective**: Deploy to production safely and verify operation
**Approval Gate**: None (executes per approved plan from Phase 5)
**Prerequisites**: Phase 5 approved, all security issues resolved

This phase executes the deployment plan and brings the application live in production.

---

## Agents in This Phase

### 1. deployment-engineer

**Status**: 🟡 Can be handled by release-manager initially
**Role**: Deployment execution and verification

#### Responsibilities

- Execute deployment according to plan
- Monitor deployment health
- Run smoke tests
- Execute database migrations
- Configure DNS/CDN
- Execute rollback if issues detected
- Generate deployment report

#### Input

- Approved release plan (from release-manager)
- Infrastructure configuration (from devops-cicd-expert)
- Smoke test checklist
- Rollback procedures

#### Deployment Execution Steps

```bash
# Pre-Deployment Verification
./scripts/pre-deploy-check.sh

# Step 1: Database Backup
echo "Creating database backup..."
kubectl exec -n production postgres-0 -- pg_dump -U postgres production_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Step 2: Run Database Migrations
echo "Running database migrations..."
kubectl run migration-job --image=ghcr.io/org/user-management:v1.0.0 \
  --restart=Never \
  --command -- python manage.py migrate --no-input

# Wait for migrations to complete
kubectl wait --for=condition=complete --timeout=300s job/migration-job

# Step 3: Deploy Application (Rolling)
echo "Deploying application..."
kubectl apply -f k8s/production/deployment.yml

# Monitor rollout
kubectl rollout status deployment/user-management -n production --timeout=10m

# Step 4: Verify Pods Running
echo "Verifying pods..."
kubectl get pods -n production -l app=user-management

# Step 5: Run Smoke Tests
echo "Running smoke tests..."
./scripts/smoke-test.sh https://api.example.com

# Step 6: Verify Metrics
echo "Checking metrics..."
./scripts/check-metrics.sh production
```

#### Output

```
## Deployment Report

**Release**: v1.0.0
**Date**: 2025-11-15 10:00 AM PST
**Deployment Duration**: 23 minutes
**Status**: ✅ SUCCESS

---

### Deployment Timeline

| Time | Event | Status |
|------|-------|--------|
| 10:00 | Deployment started | ✅ |
| 10:02 | Database backup completed | ✅ |
| 10:05 | Migrations applied successfully | ✅ |
| 10:08 | Pod 1 deployed (v1.0.0) | ✅ |
| 10:10 | Health check passed - Pod 1 | ✅ |
| 10:12 | Pod 2 deployed (v1.0.0) | ✅ |
| 10:14 | Health check passed - Pod 2 | ✅ |
| 10:16 | Pod 3 deployed (v1.0.0) | ✅ |
| 10:18 | Health check passed - Pod 3 | ✅ |
| 10:19 | All pods running v1.0.0 | ✅ |
| 10:20 | Smoke tests started | ✅ |
| 10:23 | Smoke tests passed | ✅ |
| 10:23 | Deployment complete | ✅ |

---

### Smoke Test Results

- ✅ Health endpoint: 200 OK
- ✅ User registration: SUCCESS
- ✅ User login: SUCCESS (JWT token received)
- ✅ User profile update: SUCCESS
- ✅ Role assignment: SUCCESS (admin only)
- ✅ Permission check: SUCCESS (editor cannot delete)
- ✅ Database migrations: All applied
- ✅ Response times: Within acceptable range (avg 98ms)

---

### Post-Deployment Metrics

**Immediately After Deployment**:
- Active Pods: 3/3 running
- Error Rate: 0%
- Average Response Time: 98ms
- 95th Percentile: 178ms
- Requests/Second: 45
- Memory Usage: 187MB avg per pod
- CPU Usage: 12% avg per pod

**Comparison to Pre-Deployment (Baseline)**:
- Error Rate: 0% → 0% (no change) ✅
- Avg Response Time: 95ms → 98ms (+3ms) ✅
- 95th Percentile: 172ms → 178ms (+6ms) ✅

No performance degradation detected. ✅

---

### Issues Encountered

**None** ✅

All smoke tests passed on first attempt.
No rollback required.

---

### Database Migration Results

```
Migrations applied:
  [X] 0001_initial
  [X] 0002_roles
  [X] 0003_user_roles

Migration duration: 2m 14s
Rows affected: 0 (new tables created)
```

---

### Traffic Routing

**Before Deployment**: Old version (v0.9.0) - 100%
**During Deployment**:
  - 10:08-10:10: Old (67%) + New (33%)
  - 10:12-10:14: Old (33%) + New (67%)
  - 10:16+: New (100%)

No user-facing errors during transition. ✅

---

### Rollback Status

**Rollback Required**: NO
**Rollback Readiness**: Verified (tested procedure, 15-min RTO)

---

### Recommendations

1. ✅ Deployment successful, monitor for 24 hours
2. ✅ Alert thresholds configured
3. ✅ On-call engineer assigned
4. 🔔 Schedule post-deployment review in 1 week
```

---

### 2. monitoring-specialist

**Status**: 🔴 NEW - Priority: CRITICAL
**Role**: Observability and alerting setup

#### Responsibilities

- Configure application monitoring (APM)
- Set up logging aggregation
- Create metrics dashboards
- Configure alerts and notifications
- Set up distributed tracing
- Configure error tracking
- Create uptime monitoring
- Write runbooks for common issues

#### Input

- Deployed application
- Infrastructure details
- SLA requirements
- On-call rotation

#### Output

**Monitoring Configuration:**

```yaml
# Prometheus ServiceMonitor
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: user-management
  namespace: production
spec:
  selector:
    matchLabels:
      app: user-management
  endpoints:
  - port: metrics
    interval: 30s
```

**Alert Rules:**
```yaml
# prometheus-alerts.yml
groups:
- name: user-management
  interval: 30s
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value | humanizePercentage }}"

  - alert: HighResponseTime
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 0.5
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High response time"
      description: "95th percentile response time is {{ $value }}s"

  - alert: PodDown
    expr: kube_deployment_status_replicas_available{deployment="user-management"} < 2
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Insufficient pods running"
      description: "Only {{ $value }} pods available"

  - alert: HighMemoryUsage
    expr: container_memory_usage_bytes{pod=~"user-management-.*"} / container_spec_memory_limit_bytes > 0.85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High memory usage"
      description: "Pod {{ $labels.pod }} using {{ $value | humanizePercentage }} of memory limit"
```

**Grafana Dashboard:**
```json
{
  "dashboard": {
    "title": "User Management System",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {"expr": "rate(http_requests_total[5m])"}
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {"expr": "rate(http_requests_total{status=~\"5..\"}[5m])"}
        ]
      },
      {
        "title": "Response Time (95th percentile)",
        "targets": [
          {"expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"}
        ]
      },
      {
        "title": "Active Users",
        "targets": [
          {"expr": "active_sessions"}
        ]
      }
    ]
  }
}
```

**Logging Configuration (ELK Stack):**
```yaml
# filebeat.yml
filebeat.inputs:
- type: container
  paths:
    - /var/log/containers/user-management-*.log
  processors:
    - add_kubernetes_metadata:
        host: ${NODE_NAME}
        matchers:
        - logs_path:
            logs_path: "/var/log/containers/"

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "user-management-%{+yyyy.MM.dd}"
```

**Error Tracking (Sentry):**
```python
# Django settings.py
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

sentry_sdk.init(
    dsn="https://...@sentry.io/...",
    integrations=[DjangoIntegration()],
    environment="production",
    traces_sample_rate=0.1,  # 10% of requests traced
    send_default_pii=False,  # Privacy
)
```

**Runbook:**
```markdown
# Runbook: User Management System

## Common Alerts

### Alert: HighErrorRate

**Severity**: Critical
**Description**: Error rate > 5% for 2 minutes

**Investigation Steps**:
1. Check error logs:
   ```
   kubectl logs -n production -l app=user-management --tail=100 | grep ERROR
   ```

2. Check Sentry for error details

3. Identify failing endpoint:
   ```
   # Prometheus query
   rate(http_requests_total{status=~"5.."}[5m]) by (endpoint)
   ```

**Common Causes**:
- Database connection issues
- Third-party API failure (email, OAuth)
- Memory pressure

**Resolution**:
- If database: Check DB status, restart if needed
- If API: Enable fallback, notify users
- If memory: Scale up pods temporarily

**Escalation**:
- After 5 minutes: Page on-call engineer
- After 15 minutes: Consider rollback

---

### Alert: PodDown

**Severity**: Critical
**Description**: Less than 2 pods running

**Investigation**:
```bash
kubectl get pods -n production -l app=user-management
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous  # If crashed
```

**Common Causes**:
- OOM kill
- Crash loop
- Node failure

**Resolution**:
- Check pod events
- If OOM: Increase memory limit
- If crash: Check logs, may need hotfix
- If node failure: Pods should reschedule automatically
```

---

## Phase 6 Workflow

```
Hour 1: Pre-Deployment
├─ Verify release plan approved
├─ Notify stakeholders (deployment starting)
├─ Create database backup
└─ Run pre-deployment checks

Hour 2: Deployment Execution
├─ Run database migrations
├─ Deploy to first pod (33%)
├─ Monitor health checks (10 min)
├─ Deploy to second pod (67%)
├─ Monitor health checks (10 min)
├─ Deploy to third pod (100%)
└─ Monitor health checks (10 min)

Hour 3: Verification
├─ Run smoke tests
├─ Verify all endpoints working
├─ Check error rates and response times
├─ Verify monitoring dashboards
├─ Configure alerts
└─ Generate deployment report

Post-Deployment:
├─ Notify stakeholders (deployment complete)
├─ Monitor for 24 hours
└─ Schedule post-deployment review
```

---

## Deliverables Checklist

- [ ] **Deployment Executed**
  - [ ] Database migrations applied
  - [ ] All pods running new version
  - [ ] Zero downtime achieved
  - [ ] Rollback not required

- [ ] **Smoke Tests Passed**
  - [ ] All critical flows working
  - [ ] No errors in logs
  - [ ] Response times acceptable
  - [ ] Database queries working

- [ ] **Monitoring Configured**
  - [ ] Dashboards created
  - [ ] Alerts configured
  - [ ] Logging aggregation working
  - [ ] Error tracking enabled

- [ ] **Documentation Updated**
  - [ ] Deployment report generated
  - [ ] Runbooks created
  - [ ] Stakeholders notified

---

## Rollback Procedure

If issues detected within 24 hours:

```bash
# 1. Initiate rollback
kubectl rollout undo deployment/user-management -n production

# 2. Monitor rollback
kubectl rollout status deployment/user-management -n production

# 3. Verify old version running
kubectl get pods -n production -l app=user-management

# 4. If database migration rollback needed
kubectl run migration-rollback --image=ghcr.io/org/user-management:v0.9.0 \
  --restart=Never \
  --command -- python manage.py migrate users 0002

# 5. Run smoke tests on old version
./scripts/smoke-test.sh https://api.example.com

# 6. Notify stakeholders
```

---

## Next Phase

Once deployment is stable and monitoring confirmed, proceed to [Phase 7: Post-Launch & Iteration](./phase-7-post-launch.md)