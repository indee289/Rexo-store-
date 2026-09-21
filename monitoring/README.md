# Phase 1 Critical Database Fixes - Monitoring & Alerting System

## Overview

This comprehensive monitoring and alerting system provides real-time observability for the three Phase 1 critical database fixes:

1. **Subscription Plans Schema Alignment** - Monitor interval column and seeding operations
2. **Wallet RPC Function Aliases** - Monitor credit_wallet and debit_wallet function availability
3. **Subscription Payments Table Integration** - Monitor table existence and payment operations

## 🏗️ Architecture

The monitoring system consists of multiple components working together:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │   Supabase      │    │ Phase 1 Apps    │
│   Database      │◄───┤   Functions     │◄───┤ (Flutter/Web)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Monitoring Layer                              │
├─────────────────┬─────────────────┬─────────────────────────────┤
│ PostgreSQL      │ Phase 1 Alert  │ Phase 1 Metrics           │
│ Exporter        │ System          │ Exporter                   │
│ (DB Metrics)    │ (Real-time)     │ (Custom Metrics)           │
└─────────────────┴─────────────────┴─────────────────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Prometheus                                 │
│              (Metrics Collection & Storage)                     │
└─────────────────────────────────────────────────────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Grafana     │    │  AlertManager   │    │   WebSocket     │
│  (Dashboards)   │    │ (Notifications) │    │ (Real-time UI)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Operations   │    │ Email, Slack,   │    │   Dashboard     │
│      Team       │    │ PagerDuty       │    │    Clients      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Node.js 16+ (for local development)
- PostgreSQL database with Phase 1 migrations applied
- Supabase project with service role key

### 1. Environment Setup

Create a `.env` file with your configuration:

```bash
# Database Configuration
DATABASE_URL=postgresql://user:password@host:port/database

# Supabase Configuration  
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Email Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=alerts@rexo.com
SMTP_PASS=your-app-password
SMTP_FROM=alerts@rexo.com

# Notification Channels
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
PAGERDUTY_INTEGRATION_KEY=your-pagerduty-key

# Alert Recipients
CRITICAL_EMAIL=critical-alerts@rexo.com
WARNING_EMAIL=alerts@rexo.com
DEFAULT_EMAIL=alerts@rexo.com

# Environment
ENVIRONMENT=production
```

### 2. Install Monitoring Infrastructure

```bash
# Install the monitoring database schema
psql $DATABASE_URL -f supabase/monitoring/phase1_monitoring_setup.sql

# Start the monitoring stack
docker-compose -f monitoring/docker-compose.monitoring.yml up -d

# Verify services are running
docker-compose -f monitoring/docker-compose.monitoring.yml ps
```

### 3. Access Dashboards

- **Grafana Dashboard**: http://localhost:3000 (admin/admin123)
- **Prometheus Metrics**: http://localhost:9090
- **AlertManager**: http://localhost:9093
- **Phase 1 Real-time Dashboard**: Run `./monitoring/phase1_monitoring_dashboard.sh`

## 📊 Monitoring Components

### 1. Database Monitoring Setup (`phase1_monitoring_setup.sql`)

Creates comprehensive database infrastructure:
- **Performance metrics tracking** - Execution times, success rates, error counts
- **Health check monitoring** - Schema validation, function availability  
- **Error logging** - Structured error tracking with resolution workflows
- **Alert configuration** - Flexible threshold-based alerting

Key tables:
- `phase1_performance_metrics` - Operation performance data
- `phase1_health_checks` - Component health status
- `phase1_error_log` - Error tracking and resolution  
- `phase1_alert_config` - Alert rule configuration

### 2. Real-time Alert System (`phase1_alert_system.js`)

Node.js application providing:
- **Real-time monitoring** - Continuous health and performance checks
- **Multi-channel alerting** - Email, Slack, PagerDuty integration
- **WebSocket dashboard** - Live updates for monitoring interfaces
- **Intelligent alert routing** - Component-specific notification rules

Features:
- Configurable alert thresholds
- Alert aggregation and deduplication  
- Automatic alert resolution tracking
- Daily summary reporting

### 3. Monitoring Dashboard (`phase1_monitoring_dashboard.sh`)

Interactive CLI dashboard showing:
- **Health Status** - Real-time component health indicators
- **Performance Analysis** - Success rates, response times, error rates  
- **Recent Errors** - Unresolved error tracking
- **System Resources** - Database connections, table sizes
- **Alert Configuration** - Active alert rules and triggers

Usage modes:
```bash
./phase1_monitoring_dashboard.sh dashboard    # Full dashboard  
./phase1_monitoring_dashboard.sh interactive # Real-time mode
./phase1_monitoring_dashboard.sh health      # Health only
./phase1_monitoring_dashboard.sh performance # Performance only
```

### 4. Grafana Dashboard (`phase1_grafana_dashboard.json`)

Visual monitoring interface with:
- **Component status panels** - Health indicators for all Phase 1 fixes
- **Performance time series** - Operation rates and response times
- **Error rate tracking** - Component-specific error analysis
- **Alert status table** - Active and recent alert overview
- **Resource utilization** - Database connections and storage

### 5. Prometheus Configuration

Comprehensive metrics collection:
- **Custom Phase 1 metrics** - Component-specific operational data
- **PostgreSQL metrics** - Database performance and health
- **System metrics** - Node exporter for system resources
- **Application metrics** - Container and service health

Alert rules covering:
- Critical schema issues (missing columns, tables, functions)
- Performance degradation (high error rates, slow operations)  
- Resource exhaustion (connection limits, storage growth)
- System health (service availability, migration consistency)

## 🔔 Alert Configuration

### Alert Severity Levels

| Severity | Description | Channels | Response Time |
|----------|-------------|----------|---------------|
| **Critical** | Service-affecting issues requiring immediate action | Email + Slack + PagerDuty | < 5 minutes |
| **Warning** | Performance issues requiring attention | Email + Slack | < 30 minutes |
| **Info** | Informational notifications | Slack only | No SLA |

### Component-Specific Alerts

#### Subscription Plans
- `SubscriptionPlansSchemaInvalid` - Missing interval column (Critical)
- `SubscriptionPlansHighErrorRate` - Error rate > 5% (Warning)
- `SubscriptionPlansSlowOperations` - Avg response > 1000ms (Warning)
- `SubscriptionPlansSeedingFailure` - Seeding script failure (Critical)

#### Wallet Functions  
- `WalletFunctionsMissing` - Missing credit/debit functions (Critical)
- `WalletFunctionsHighErrorRate` - Error rate > 3% (Warning)
- `WalletFunctionsSlowOperations` - Avg response > 2000ms (Warning)
- `WalletBalanceInconsistency` - Balance calculation errors (Critical)

#### Subscription Payments
- `SubscriptionPaymentsTableMissing` - Missing table (Critical)
- `SubscriptionPaymentsHighErrorRate` - Error rate > 5% (Warning)  
- `SubscriptionPaymentsNoActivity` - No operations for 1 hour (Info)

### Alert Routing Rules

```yaml
# Critical alerts - All channels, immediate notification
- severity: critical
  channels: [email, slack, pagerduty]
  repeat_interval: 5m

# Warning alerts - Email and Slack  
- severity: warning
  channels: [email, slack]
  repeat_interval: 30m

# Team-specific routing
- component: subscription_plans
  channel: #subscription-team
- component: wallet_functions  
  channel: #wallet-team
- component: subscription_payments
  channel: #payments-team
```

## 📈 Metrics and KPIs

### Key Performance Indicators

1. **Availability**
   - Schema component availability (subscription_plans.interval, wallet functions, subscription_payments table)
   - Target: 99.9% availability

2. **Performance**  
   - Average response time per operation type
   - 95th percentile response time
   - Target: < 500ms average, < 1000ms 95th percentile

3. **Reliability**
   - Success rate per component
   - Error rate trends
   - Target: > 99% success rate, < 1% error rate

4. **Health Score**
   - Composite health metric (0-1 scale)
   - Weighted by schema health (60%) and operation success (40%)  
   - Target: > 0.95 overall health score

### Custom Metrics

The monitoring system exposes these Phase 1 specific metrics:

```
# Schema validation metrics
phase1_subscription_plans_schema_valid
phase1_wallet_functions_available  
phase1_subscription_payments_table_exists

# Performance metrics
phase1_operation_duration_seconds
phase1_operations_total
phase1_operations_success_total
phase1_operations_errors_total

# Health metrics  
phase1_component_health_score
phase1_overall_health_score
phase1_migration_consistency_check

# Error tracking
phase1_recent_errors_total
phase1_unresolved_errors_total
```

## 🛠️ Operations Guide

### Daily Operations

1. **Morning Health Check** (9:00 AM)
   ```bash
   ./phase1_monitoring_dashboard.sh health
   ```

2. **Performance Review** (2:00 PM)  
   ```bash
   ./phase1_monitoring_dashboard.sh performance
   ```

3. **End of Day Summary** (6:00 PM)
   ```bash
   ./phase1_monitoring_dashboard.sh report
   ```

### Weekly Operations

1. **Alert Threshold Review** - Analyze alert frequency and adjust thresholds
2. **Performance Trend Analysis** - Review weekly performance trends  
3. **Capacity Planning** - Monitor resource utilization trends
4. **Dashboard Updates** - Update dashboards based on operational feedback

### Monthly Operations

1. **Full System Validation** - Comprehensive health assessment
2. **Documentation Updates** - Update runbooks and procedures
3. **Monitoring System Updates** - Apply updates and security patches
4. **Disaster Recovery Testing** - Test monitoring system resilience

### Incident Response

#### Critical Alert Response

1. **Immediate Response** (< 5 minutes)
   - Acknowledge alert in PagerDuty/Slack
   - Access Grafana dashboard for context
   - Check recent deployments/changes

2. **Investigation** (< 15 minutes)
   - Run health check: `./phase1_monitoring_dashboard.sh health`
   - Check database connectivity  
   - Review recent error logs

3. **Resolution** (< 30 minutes)
   - Apply immediate fixes if identified
   - Execute rollback procedures if necessary
   - Document incident and resolution

#### Alert Escalation Path

```
Level 1: Development Team (0-15 minutes)
    ↓ (if unresolved)
Level 2: Senior Developer/DBA (15-30 minutes)  
    ↓ (if unresolved)
Level 3: Engineering Manager (30-60 minutes)
    ↓ (if unresolved)  
Level 4: CTO/Executive Team (60+ minutes)
```

## 🔧 Configuration

### Customizing Alert Thresholds

Update alert thresholds in the database:

```sql
UPDATE phase1_alert_config 
SET threshold_value = 3
WHERE alert_name = 'subscription_plans_high_error_rate';
```

### Adding Custom Metrics

1. Add new metrics to `postgres_exporter_queries.yaml`
2. Update Prometheus configuration to scrape new metrics
3. Create Grafana panels for visualization  
4. Add alert rules in `prometheus_rules.yml`

### Notification Channel Configuration

#### Slack Integration
```bash
# Set webhook URL
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

# Test notification
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Phase 1 monitoring test"}' \
  $SLACK_WEBHOOK_URL
```

#### Email Configuration  
```bash
# Configure SMTP settings
export SMTP_HOST="smtp.gmail.com"
export SMTP_PORT="587"
export SMTP_USER="alerts@rexo.com"
export SMTP_PASS="your-app-password"
```

#### PagerDuty Integration
```bash
# Set integration key
export PAGERDUTY_INTEGRATION_KEY="your-integration-key"

# Test alert
curl -X POST 'https://events.pagerduty.com/v2/enqueue' \
  -H 'Content-Type: application/json' \
  -d '{
    "routing_key": "'$PAGERDUTY_INTEGRATION_KEY'",
    "event_action": "trigger",
    "payload": {
      "summary": "Phase 1 monitoring test",
      "severity": "info",
      "source": "phase1-test"
    }
  }'
```

## 🧪 Testing

### Monitoring System Health Check

```bash
# Test database connectivity
node -e "
const { createClient } = require('@supabase/supabase-js');
const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);
client.rpc('check_phase1_health').then(console.log);
"

# Test alert system  
curl http://localhost:8080/health

# Test metrics endpoint
curl http://localhost:9092/metrics
```

### Simulating Alerts

```bash
# Simulate schema issue
psql $DATABASE_URL -c "DROP COLUMN IF EXISTS interval FROM subscription_plans;"

# Simulate performance issue  
psql $DATABASE_URL -c "
INSERT INTO phase1_performance_metrics (
  component_name, operation_type, execution_time_ms, success
) VALUES ('subscription_plans', 'test_slow', 5000, false);
"

# Restore schema
psql $DATABASE_URL -f supabase/migrations/fix_subscription_plans_schema.sql
```

## 📚 Troubleshooting

### Common Issues

#### Dashboard Not Loading
```bash
# Check service status
docker-compose -f monitoring/docker-compose.monitoring.yml ps

# Check logs
docker-compose -f monitoring/docker-compose.monitoring.yml logs grafana
```

#### Alerts Not Firing
```bash  
# Check AlertManager status
curl http://localhost:9093/api/v1/status

# Validate alert rules
promtool check rules monitoring/prometheus_rules.yml

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
```

#### Database Connection Issues
```bash
# Test database connectivity  
psql $DATABASE_URL -c "SELECT 1;"

# Check monitoring tables exist
psql $DATABASE_URL -c "\\dt phase1_*"

# Verify monitoring functions
psql $DATABASE_URL -c "SELECT check_phase1_health();"
```

#### High Resource Usage
```bash
# Check container resource usage
docker stats

# Check database connections
psql $DATABASE_URL -c "SELECT count(*) FROM pg_stat_activity;"

# Monitor disk usage
df -h
```

### Log Analysis

```bash
# Phase 1 alert system logs
docker logs phase1-alert-system -f

# Prometheus logs  
docker logs phase1-prometheus -f

# PostgreSQL exporter logs
docker logs phase1-postgres-exporter -f
```

## 🔒 Security

### Access Control

- **Grafana**: Admin access required for dashboard editing
- **Prometheus**: Read-only access for metrics queries
- **AlertManager**: Admin access for configuration changes
- **Database**: Service role key with limited permissions

### Data Protection

- **Metrics retention**: 30 days in Prometheus  
- **Log retention**: 7 days in containers
- **Alert history**: 90 days in AlertManager
- **Sensitive data**: Excluded from metrics collection

### Network Security

- **Internal networks**: All services on isolated Docker network
- **TLS encryption**: Enabled for external communications
- **Authentication**: Required for all administrative interfaces
- **Rate limiting**: Applied to notification channels

## 📞 Support

### Documentation
- [Phase 1 Implementation Guide](../PHASE_1_CRITICAL_FIXES_GUIDE.md)
- [Rollback Procedures](../ROLLBACK_PROCEDURES_DOCUMENTATION.md)  
- [Operational Procedures](../OPERATIONAL_PROCEDURES.md)

### Contact Information
- **Development Team**: dev-team@rexo.com
- **Operations Team**: ops-team@rexo.com  
- **Emergency Contact**: emergency@rexo.com
- **On-call Phone**: +1-555-REXO-OPS

### Resources
- **Slack Channel**: #phase1-monitoring
- **Issue Tracker**: https://github.com/rexo-marketplace/issues
- **Status Page**: https://status.rexo.com
- **Documentation**: https://docs.rexo.com/monitoring