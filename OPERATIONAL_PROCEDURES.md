# Operational Procedures - Phase 1 Critical Database Fixes

## Overview

This document provides operational procedures for monitoring, maintaining, and troubleshooting the Phase 1 critical database fixes in production. It covers daily operations, performance monitoring, security validation, and incident response procedures.

## Quick Reference

### Emergency Contacts
| Role | Primary Contact | Backup Contact | Escalation |
|------|----------------|----------------|------------|
| Database Admin | [Name] - [Phone] | [Name] - [Phone] | [Manager] |
| Development Lead | [Name] - [Phone] | [Name] - [Phone] | [CTO] |
| Operations Team | [Name] - [Phone] | [Name] - [Phone] | [VP Ops] |

### Critical Commands
```bash
# Check migration status
./check_phase1_status.sh

# Run health validation
./validate_phase1_migrations.js

# Emergency rollback
./emergency_rollback.sh

# Performance analysis
./analyze_phase1_performance.sh
```

## Daily Operations

### Morning Health Check (9:00 AM)

#### Database Health Validation
```bash
#!/bin/bash
# daily_health_check.sh

echo "=== Daily Phase 1 Health Check - $(date) ==="

# 1. Check migration status
echo "1. Checking migration status..."
psql $DATABASE_URL -c "
SELECT 
    'Migration Component' as component,
    CASE 
        WHEN EXISTS(SELECT 1 FROM information_schema.columns 
                   WHERE table_name='subscription_plans' AND column_name='interval')
        THEN '✅ Active' ELSE '❌ Missing' 
    END as subscription_plans_interval,
    
    CASE 
        WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname='credit_wallet')
        THEN '✅ Active' ELSE '❌ Missing'
    END as credit_wallet_function,
    
    CASE 
        WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname='debit_wallet')
        THEN '✅ Active' ELSE '❌ Missing'
    END as debit_wallet_function,
    
    CASE 
        WHEN EXISTS(SELECT 1 FROM information_schema.tables 
                   WHERE table_name='subscription_payments')
        THEN '✅ Active' ELSE '❌ Missing'
    END as subscription_payments_table;
"

# 2. Check data integrity
echo "2. Checking data integrity..."
psql $DATABASE_URL -c "
SELECT 
    'Data Integrity' as check_type,
    COUNT(*) as total_subscription_plans,
    COUNT(*) FILTER (WHERE interval IS NOT NULL) as plans_with_interval,
    COUNT(*) FILTER (WHERE duration_days > 0) as plans_with_duration
FROM subscription_plans;
"

# 3. Test function accessibility
echo "3. Testing function accessibility..."
psql $DATABASE_URL -c "
SELECT 
    proname as function_name,
    pronargs as argument_count,
    prosecdef as security_definer,
    CASE 
        WHEN proacl IS NULL THEN 'Public Access'
        ELSE 'Restricted Access'
    END as access_level
FROM pg_proc 
WHERE proname IN ('credit_wallet', 'debit_wallet', 'increment_wallet_balance', 'decrement_wallet_balance')
ORDER BY proname;
"

# 4. Check recent activity
echo "4. Checking recent activity (last 24 hours)..."
psql $DATABASE_URL -c "
SELECT 
    'Recent Activity' as metric,
    (SELECT COUNT(*) FROM subscription_payments 
     WHERE created_at > NOW() - INTERVAL '24 hours') as new_payments,
    (SELECT COUNT(*) FROM subscription_plans 
     WHERE created_at > NOW() - INTERVAL '24 hours') as new_plans,
    (SELECT SUM(calls) FROM pg_stat_statements 
     WHERE query LIKE '%credit_wallet%' OR query LIKE '%debit_wallet%') as wallet_function_calls;
"

echo "Daily health check completed - $(date)"
```

#### Performance Metrics Collection
```bash
#!/bin/bash
# collect_performance_metrics.sh

echo "=== Performance Metrics Collection ==="

# Database performance
psql $DATABASE_URL -c "
SELECT 
    schemaname,
    relname as table_name,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins as inserts_24h,
    n_tup_upd as updates_24h
FROM pg_stat_user_tables 
WHERE relname IN ('subscription_plans', 'subscription_payments')
ORDER BY relname;
"

# Query performance analysis
psql $DATABASE_URL -c "
SELECT 
    substring(query, 1, 60) as query_sample,
    calls,
    total_time,
    mean_time,
    stddev_time,
    rows
FROM pg_stat_statements 
WHERE query ILIKE '%subscription%' OR query ILIKE '%wallet%'
ORDER BY mean_time DESC
LIMIT 10;
"
```

### Weekly Maintenance (Every Sunday)

#### Deep Performance Analysis
```bash
#!/bin/bash
# weekly_performance_analysis.sh

echo "=== Weekly Performance Analysis - $(date) ==="

# Index usage analysis
echo "1. Index Usage Analysis..."
psql $DATABASE_URL -c "
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED INDEX'
        WHEN idx_scan < 100 THEN 'LOW USAGE' 
        ELSE 'ACTIVE'
    END as status
FROM pg_stat_user_indexes 
WHERE tablename IN ('subscription_plans', 'subscription_payments')
ORDER BY tablename, idx_scan DESC;
"

# Table bloat analysis
echo "2. Table Bloat Analysis..."
psql $DATABASE_URL -c "
SELECT 
    schemaname,
    tablename,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples,
    ROUND(n_dead_tup * 100.0 / GREATEST(n_live_tup + n_dead_tup, 1), 2) as bloat_percentage,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables 
WHERE tablename IN ('subscription_plans', 'subscription_payments')
ORDER BY bloat_percentage DESC;
"

# Function performance analysis
echo "3. Function Performance Analysis..."
psql $DATABASE_URL -c "
SELECT 
    funcname,
    calls,
    total_time,
    self_time,
    mean_time,
    mean_self_time
FROM pg_stat_user_functions 
WHERE funcname LIKE '%wallet%' OR funcname LIKE '%subscription%'
ORDER BY mean_time DESC;
"
```

#### Security Audit
```bash
#!/bin/bash
# weekly_security_audit.sh

echo "=== Weekly Security Audit - $(date) ==="

# RLS policy validation
echo "1. RLS Policy Validation..."
psql $DATABASE_URL -c "
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as command_type,
    CASE 
        WHEN qual IS NOT NULL THEN 'Has WHERE condition'
        ELSE 'No WHERE condition'
    END as where_clause_status
FROM pg_policies 
WHERE tablename IN ('subscription_plans', 'subscription_payments')
ORDER BY tablename, policyname;
"

# Function permissions audit
echo "2. Function Permissions Audit..."
psql $DATABASE_URL -c "
SELECT 
    proname as function_name,
    proowner::regrole as owner,
    prosecdef as security_definer,
    CASE 
        WHEN proacl IS NULL THEN 'PUBLIC ACCESS - REVIEW NEEDED'
        ELSE array_to_string(proacl, ', ')
    END as access_control
FROM pg_proc 
WHERE proname IN ('credit_wallet', 'debit_wallet', 'increment_wallet_balance', 'decrement_wallet_balance')
ORDER BY proname;
"

# Recent access patterns
echo "3. Recent Access Patterns..."
psql $DATABASE_URL -c "
SELECT 
    usename as username,
    application_name,
    COUNT(*) as connection_count,
    MAX(backend_start) as last_connection
FROM pg_stat_activity 
WHERE datname = current_database()
AND backend_start > NOW() - INTERVAL '7 days'
GROUP BY usename, application_name
ORDER BY connection_count DESC;
"
```

## Monitoring and Alerting

### Critical Metrics Dashboard

#### Key Performance Indicators (KPIs)
```yaml
# monitoring_kpis.yml
phase1_kpis:
  database_health:
    - metric: "migration_component_availability"
      query: "SELECT COUNT(*) FROM (SELECT 1 WHERE EXISTS(...)) AS components"
      threshold: "= 4"  # All 4 components must be active
      alert_level: "critical"

    - metric: "subscription_plans_integrity"
      query: "SELECT COUNT(*) FROM subscription_plans WHERE interval IS NULL"
      threshold: "= 0"  # No records should have NULL interval
      alert_level: "high"

  performance_metrics:
    - metric: "wallet_function_response_time"
      query: "SELECT mean_time FROM pg_stat_statements WHERE query LIKE '%wallet%'"
      threshold: "< 200"  # milliseconds
      alert_level: "medium"

    - metric: "subscription_payments_query_time"
      query: "SELECT mean_time FROM pg_stat_statements WHERE query LIKE '%subscription_payments%'"
      threshold: "< 150"  # milliseconds
      alert_level: "medium"

  business_metrics:
    - metric: "subscription_payments_success_rate"
      query: "SELECT (completed::float / total) * 100 FROM payment_stats"
      threshold: "> 95"  # percentage
      alert_level: "high"

    - metric: "wallet_operations_error_rate"
      query: "SELECT error_percentage FROM wallet_operation_stats"
      threshold: "< 1"   # percentage
      alert_level: "high"
```

#### Automated Alerting Rules
```bash
#!/bin/bash
# automated_alerting.sh

# Run every 5 minutes via cron
# */5 * * * * /path/to/automated_alerting.sh

ALERT_THRESHOLD=5
ERROR_COUNT=0

# Check 1: Migration components availability
echo "Checking migration components..."
COMPONENT_COUNT=$(psql $DATABASE_URL -t -c "
SELECT 
    (CASE WHEN EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='subscription_plans' AND column_name='interval') THEN 1 ELSE 0 END) +
    (CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname='credit_wallet') THEN 1 ELSE 0 END) +
    (CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname='debit_wallet') THEN 1 ELSE 0 END) +
    (CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name='subscription_payments') THEN 1 ELSE 0 END);
" | xargs)

if [ "$COMPONENT_COUNT" -ne 4 ]; then
    echo "CRITICAL: Migration components missing (found $COMPONENT_COUNT/4)"
    # Send critical alert
    curl -X POST $WEBHOOK_URL -d "{\"alert\":\"critical\",\"message\":\"Migration components missing\"}"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi

# Check 2: Data integrity
echo "Checking data integrity..."
NULL_INTERVALS=$(psql $DATABASE_URL -t -c "SELECT COUNT(*) FROM subscription_plans WHERE interval IS NULL;" | xargs)

if [ "$NULL_INTERVALS" -gt 0 ]; then
    echo "WARNING: Found $NULL_INTERVALS subscription plans with NULL interval"
    # Send warning alert
    curl -X POST $WEBHOOK_URL -d "{\"alert\":\"warning\",\"message\":\"Data integrity issue detected\"}"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi

# Check 3: Function performance
echo "Checking function performance..."
SLOW_QUERIES=$(psql $DATABASE_URL -t -c "
SELECT COUNT(*) FROM pg_stat_statements 
WHERE (query LIKE '%credit_wallet%' OR query LIKE '%debit_wallet%') 
AND mean_time > 200;
" | xargs)

if [ "$SLOW_QUERIES" -gt 0 ]; then
    echo "WARNING: Detected $SLOW_QUERIES slow wallet function queries"
    # Send performance alert
    curl -X POST $WEBHOOK_URL -d "{\"alert\":\"performance\",\"message\":\"Slow wallet function queries detected\"}"
    ERROR_COUNT=$((ERROR_COUNT + 1))
fi

# Summary
if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✅ All automated checks passed"
else
    echo "⚠️  Detected $ERROR_COUNT issues requiring attention"
fi
```

### Real-time Monitoring Setup

#### Grafana Dashboard Configuration
```json
{
  "dashboard": {
    "title": "Phase 1 Database Fixes - Operations Dashboard",
    "panels": [
      {
        "title": "Migration Component Status",
        "type": "stat",
        "targets": [
          {
            "expr": "postgresql_custom{job=\"phase1_components\"}",
            "legendFormat": "Components Active"
          }
        ],
        "thresholds": [
          {"color": "red", "value": 0},
          {"color": "yellow", "value": 3},
          {"color": "green", "value": 4}
        ]
      },
      {
        "title": "Wallet Function Performance",
        "type": "graph",
        "targets": [
          {
            "expr": "postgresql_function_calls_total{function=~\"credit_wallet|debit_wallet\"}",
            "legendFormat": "{{function}} calls"
          },
          {
            "expr": "postgresql_function_duration_seconds{function=~\"credit_wallet|debit_wallet\"}",
            "legendFormat": "{{function}} duration"
          }
        ]
      },
      {
        "title": "Subscription Operations",
        "type": "graph", 
        "targets": [
          {
            "expr": "postgresql_table_rows_total{table=\"subscription_plans\"}",
            "legendFormat": "Subscription Plans"
          },
          {
            "expr": "postgresql_table_rows_total{table=\"subscription_payments\"}",
            "legendFormat": "Subscription Payments"
          }
        ]
      }
    ]
  }
}
```

#### Prometheus Metrics Collection
```yaml
# prometheus_config.yml
scrape_configs:
  - job_name: 'phase1_database_metrics'
    static_configs:
      - targets: ['localhost:9187']  # postgres_exporter
    scrape_interval: 30s
    metrics_path: /metrics
    
  - job_name: 'phase1_custom_metrics'
    static_configs:
      - targets: ['localhost:8080']  # Custom metrics endpoint
    scrape_interval: 60s

rule_files:
  - "phase1_alerting_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
```

## Troubleshooting Procedures

### Common Issues and Solutions

#### Issue 1: Subscription Plan Seeding Failures

**Symptoms:**
- Error: "column interval does not exist"
- Seed scripts failing to execute
- New subscription plans cannot be created

**Diagnosis:**
```bash
#!/bin/bash
# diagnose_subscription_plans.sh

echo "=== Diagnosing Subscription Plans Issues ==="

# Check if interval column exists
echo "1. Checking interval column..."
psql $DATABASE_URL -c "
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'subscription_plans' AND column_name = 'interval';
"

# Check existing data
echo "2. Checking existing data..."
psql $DATABASE_URL -c "
SELECT 
    COUNT(*) as total_plans,
    COUNT(*) FILTER (WHERE interval IS NOT NULL) as plans_with_interval,
    COUNT(*) FILTER (WHERE interval IS NULL) as plans_without_interval
FROM subscription_plans;
"

# Test insert operation
echo "3. Testing insert operation..."
psql $DATABASE_URL -c "
INSERT INTO subscription_plans (name, duration_days, interval, price) 
VALUES ('test_plan_diagnostic', 30, 'month', 9.99);
DELETE FROM subscription_plans WHERE name = 'test_plan_diagnostic';
SELECT 'Insert test completed successfully' as result;
"
```

**Solution:**
```bash
#!/bin/bash
# fix_subscription_plans.sh

echo "Fixing subscription plans issue..."

# Re-apply migration 1 if needed
psql $DATABASE_URL << 'EOF'
-- Add interval column if missing
ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS interval TEXT;

-- Update existing records
UPDATE subscription_plans SET interval = CASE
    WHEN duration_days = 7 THEN 'week'
    WHEN duration_days = 30 THEN 'month'
    WHEN duration_days = 90 THEN 'quarter'
    WHEN duration_days = 365 THEN 'year'
    ELSE 'month'
END
WHERE interval IS NULL;

-- Add constraint
ALTER TABLE subscription_plans 
ADD CONSTRAINT IF NOT EXISTS chk_subscription_interval 
CHECK (interval IN ('day', 'week', 'month', 'quarter', 'year'));

SELECT 'Subscription plans issue fixed' as result;
EOF
```

#### Issue 2: Wallet Function Access Denied

**Symptoms:**
- Error: "function credit_wallet does not exist"
- Error: "permission denied for function credit_wallet"
- Admin operations failing

**Diagnosis:**
```bash
#!/bin/bash
# diagnose_wallet_functions.sh

echo "=== Diagnosing Wallet Function Issues ==="

# Check if functions exist
echo "1. Checking function existence..."
psql $DATABASE_URL -c "
SELECT 
    proname as function_name,
    pronargs as arg_count,
    prosecdef as security_definer,
    proowner::regrole as owner
FROM pg_proc 
WHERE proname IN ('credit_wallet', 'debit_wallet', 'increment_wallet_balance', 'decrement_wallet_balance')
ORDER BY proname;
"

# Check function permissions
echo "2. Checking function permissions..."
psql $DATABASE_URL -c "
SELECT 
    proname as function_name,
    CASE 
        WHEN proacl IS NULL THEN 'PUBLIC ACCESS'
        ELSE array_to_string(proacl, ', ')
    END as permissions
FROM pg_proc 
WHERE proname IN ('credit_wallet', 'debit_wallet')
ORDER BY proname;
"

# Test function calls (will show permission/existence errors)
echo "3. Testing function accessibility..."
psql $DATABASE_URL -c "
SELECT 'Testing function calls...' as status;
-- These will fail with specific error messages
SELECT 'credit_wallet test' as test;
SELECT 'debit_wallet test' as test;
"
```

**Solution:**
```bash
#!/bin/bash
# fix_wallet_functions.sh

echo "Fixing wallet function issues..."

# Re-create function aliases
psql $DATABASE_URL -f supabase/migrations/add_wallet_function_aliases.sql

# Verify permissions are correctly set
psql $DATABASE_URL << 'EOF'
-- Ensure proper permissions
REVOKE ALL ON FUNCTION credit_wallet FROM PUBLIC;
REVOKE ALL ON FUNCTION debit_wallet FROM PUBLIC;

-- Grant to admin role only
GRANT EXECUTE ON FUNCTION credit_wallet TO admin_role;
GRANT EXECUTE ON FUNCTION debit_wallet TO admin_role;

-- Verify permissions
SELECT 
    proname,
    CASE 
        WHEN proacl IS NULL THEN 'PUBLIC ACCESS - ERROR'
        ELSE 'RESTRICTED ACCESS - OK'
    END as permission_status
FROM pg_proc 
WHERE proname IN ('credit_wallet', 'debit_wallet');
EOF

echo "Wallet function permissions fixed"
```

#### Issue 3: Subscription Payments Table Access Issues

**Symptoms:**
- Error: "table subscription_payments does not exist"
- Error: "permission denied for table subscription_payments"
- Payment operations failing

**Diagnosis:**
```bash
#!/bin/bash
# diagnose_subscription_payments.sh

echo "=== Diagnosing Subscription Payments Issues ==="

# Check if table exists
echo "1. Checking table existence..."
psql $DATABASE_URL -c "
SELECT 
    table_name,
    table_type,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'subscription_payments';
"

# Check RLS policies
echo "2. Checking RLS policies..."
psql $DATABASE_URL -c "
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'subscription_payments'
ORDER BY policyname;
"

# Check indexes
echo "3. Checking indexes..."
psql $DATABASE_URL -c "
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'subscription_payments'
ORDER BY indexname;
"

# Test basic operations
echo "4. Testing basic operations..."
psql $DATABASE_URL -c "
-- Test SELECT (should work for authenticated users)
SELECT COUNT(*) as record_count FROM subscription_payments;

-- Test table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'subscription_payments'
ORDER BY ordinal_position;
"
```

**Solution:**
```bash
#!/bin/bash
# fix_subscription_payments.sh

echo "Fixing subscription payments table issues..."

# Re-apply migration 3 if needed
psql $DATABASE_URL -f supabase/migrations/integrate_subscription_payments.sql

# Verify table and policies are properly configured
psql $DATABASE_URL << 'EOF'
-- Verify RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'subscription_payments';

-- Check policy count
SELECT 
    COUNT(*) as policy_count
FROM pg_policies 
WHERE tablename = 'subscription_payments';

SELECT 'Subscription payments table verification completed' as result;
EOF

echo "Subscription payments table fixed"
```

## Incident Response Procedures

### Severity Levels and Response Times

| Severity | Description | Response Time | Escalation |
|----------|-------------|---------------|------------|
| **Critical** | Database unavailable, data loss | 15 minutes | Immediate |
| **High** | Major function failures, security issues | 1 hour | 30 minutes |
| **Medium** | Performance degradation, minor failures | 4 hours | 2 hours |
| **Low** | Documentation, cosmetic issues | 24 hours | None |

### Incident Response Workflow

#### Critical Incident Response
```bash
#!/bin/bash
# critical_incident_response.sh

INCIDENT_ID=$1
INCIDENT_DESCRIPTION="$2"

echo "🚨 CRITICAL INCIDENT RESPONSE - ID: $INCIDENT_ID"
echo "Description: $INCIDENT_DESCRIPTION"
echo "Started at: $(date)"

# Step 1: Immediate assessment
echo "=== Step 1: Immediate Assessment ==="
./immediate_health_check.sh

# Step 2: Determine if rollback is needed
echo "=== Step 2: Rollback Decision ==="
read -p "Execute emergency rollback? (yes/no): " rollback_decision

if [ "$rollback_decision" = "yes" ]; then
    echo "Executing emergency rollback..."
    ./emergency_rollback.sh
    
    # Notify stakeholders
    echo "Notifying stakeholders of rollback..."
    curl -X POST $NOTIFICATION_WEBHOOK \
         -d "{\"incident_id\":\"$INCIDENT_ID\",\"action\":\"rollback_executed\",\"timestamp\":\"$(date)\"}"
else
    echo "Proceeding with targeted fix..."
    # Continue with targeted troubleshooting
fi

# Step 3: Document incident
echo "=== Step 3: Documentation ==="
cat > "incident_${INCIDENT_ID}_$(date +%Y%m%d_%H%M%S).log" << EOF
Incident ID: $INCIDENT_ID
Description: $INCIDENT_DESCRIPTION
Start Time: $(date)
Actions Taken:
- Immediate assessment completed
- Rollback decision: $rollback_decision
- [Add additional actions here]

Next Steps:
- [Add investigation steps]
- [Add preventive measures]
EOF

echo "Critical incident response completed"
```

#### High Priority Incident Response
```bash
#!/bin/bash  
# high_priority_incident_response.sh

INCIDENT_ID=$1
AFFECTED_COMPONENT="$2"

echo "⚠️ HIGH PRIORITY INCIDENT - ID: $INCIDENT_ID"
echo "Affected Component: $AFFECTED_COMPONENT"

case $AFFECTED_COMPONENT in
    "subscription_plans")
        echo "Running subscription plans diagnostics..."
        ./diagnose_subscription_plans.sh
        
        # Attempt automatic fix
        ./fix_subscription_plans.sh
        ;;
        
    "wallet_functions")
        echo "Running wallet functions diagnostics..."
        ./diagnose_wallet_functions.sh
        
        # Attempt automatic fix
        ./fix_wallet_functions.sh
        ;;
        
    "subscription_payments")
        echo "Running subscription payments diagnostics..."
        ./diagnose_subscription_payments.sh
        
        # Attempt automatic fix
        ./fix_subscription_payments.sh
        ;;
        
    *)
        echo "Unknown component: $AFFECTED_COMPONENT"
        echo "Running general diagnostics..."
        ./validate_phase1_migrations.js
        ;;
esac

# Verify fix
echo "Verifying fix effectiveness..."
./validate_phase1_migrations.js

echo "High priority incident response completed"
```

### Post-Incident Procedures

#### Post-Incident Review Template
```markdown
# Post-Incident Review - [INCIDENT_ID]

## Incident Summary
- **Date**: [DATE]
- **Duration**: [START_TIME] - [END_TIME] 
- **Severity**: [Critical/High/Medium/Low]
- **Affected Systems**: Phase 1 Database Fixes
- **Impact**: [Description of business impact]

## Timeline
- **[TIME]**: Incident detected
- **[TIME]**: Response team assembled
- **[TIME]**: Initial assessment completed
- **[TIME]**: Fix implemented
- **[TIME]**: Service restored
- **[TIME]**: Incident resolved

## Root Cause Analysis
- **Primary Cause**: [Technical cause]
- **Contributing Factors**: [Additional factors]
- **Detection Method**: [How was it discovered]

## Resolution Actions
1. **Immediate Actions**: [What was done to restore service]
2. **Temporary Workarounds**: [Any temporary measures]
3. **Permanent Fix**: [Long-term solution implemented]

## Lessons Learned
- **What Worked Well**: [Successful aspects of response]
- **What Could Be Improved**: [Areas for enhancement]
- **Preventive Measures**: [How to prevent recurrence]

## Action Items
| Action | Owner | Due Date | Status |
|--------|--------|----------|--------|
| [Action 1] | [Owner] | [Date] | [Status] |
| [Action 2] | [Owner] | [Date] | [Status] |

## Appendices
- Incident logs
- Database query results
- Performance metrics during incident
- Communication timeline
```

## Backup and Recovery Procedures

### Automated Backup Schedule

```bash
#!/bin/bash
# automated_backup.sh

# Run via cron: 0 2 * * * /path/to/automated_backup.sh

BACKUP_DIR="/backups/phase1"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="phase1_backup_${TIMESTAMP}.sql"

echo "Starting Phase 1 backup - $TIMESTAMP"

# Create backup directory
mkdir -p $BACKUP_DIR

# Full database backup
pg_dump $DATABASE_URL \
    --verbose \
    --no-owner \
    --no-privileges \
    --format=custom \
    --file="${BACKUP_DIR}/${BACKUP_FILE}"

# Verify backup
if pg_restore --list "${BACKUP_DIR}/${BACKUP_FILE}" > /dev/null 2>&1; then
    echo "✅ Backup created successfully: $BACKUP_FILE"
    
    # Compress backup
    gzip "${BACKUP_DIR}/${BACKUP_FILE}"
    
    # Upload to cloud storage (if configured)
    if [ ! -z "$S3_BACKUP_BUCKET" ]; then
        aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}.gz" "s3://${S3_BACKUP_BUCKET}/phase1/"
    fi
    
    # Clean up old backups (keep 30 days)
    find $BACKUP_DIR -name "phase1_backup_*.sql.gz" -mtime +30 -delete
    
else
    echo "❌ Backup verification failed"
    exit 1
fi
```

### Recovery Testing

```bash
#!/bin/bash
# test_recovery.sh

BACKUP_FILE=$1
TEST_DB_NAME="phase1_recovery_test_$(date +%Y%m%d_%H%M%S)"

echo "Testing recovery from backup: $BACKUP_FILE"

# Create test database
createdb $TEST_DB_NAME

# Restore backup
pg_restore \
    --dbname=$TEST_DB_NAME \
    --verbose \
    --clean \
    --if-exists \
    $BACKUP_FILE

# Validate restored data
psql $TEST_DB_NAME -c "
SELECT 
    'Recovery Test Results' as test_type,
    (SELECT COUNT(*) FROM subscription_plans) as subscription_plans_count,
    (SELECT COUNT(*) FROM subscription_payments) as subscription_payments_count,
    (SELECT COUNT(*) FROM pg_proc WHERE proname IN ('credit_wallet', 'debit_wallet')) as wallet_functions_count;
"

# Clean up test database
dropdb $TEST_DB_NAME

echo "Recovery test completed"
```

---

**Document Version**: 1.0  
**Last Updated**: January 2024  
**Operations Guide Version**: Phase 1 Complete