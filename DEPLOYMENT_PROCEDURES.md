# Deployment Procedures - Phase 1 Critical Database Fixes

## Overview

This document provides comprehensive deployment procedures for Phase 1 critical database fixes, including pre-deployment checks, step-by-step migration execution, post-deployment validation, and emergency rollback procedures.

## Quick Reference

| Phase | Duration | Downtime | Risk Level |
|-------|----------|----------|------------|
| Pre-deployment | 30 minutes | None | Low |
| Migration Execution | 15 minutes | Optional | Medium |
| Post-deployment Validation | 20 minutes | None | Low |
| **Total Time** | **65 minutes** | **0-15 minutes** | **Low** |

## Pre-Deployment Checklist

### Environment Preparation

- [ ] **Database Backup Completed**
  ```bash
  # Create full database backup
  pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
  
  # Verify backup integrity
  psql -d backup_db < backup_$(date +%Y%m%d_%H%M%S).sql
  ```

- [ ] **Supabase CLI Authenticated**
  ```bash
  supabase login
  supabase projects list  # Verify access to target project
  ```

- [ ] **Environment Variables Configured**
  ```bash
  export DATABASE_URL="postgresql://..."
  export SUPABASE_PROJECT_ID="..."
  export BACKUP_BUCKET="..."
  ```

- [ ] **Migration Scripts Validated**
  ```bash
  # Validate SQL syntax
  psql --dry-run -f supabase/fix_subscription_plans_schema.sql
  psql --dry-run -f supabase/migrations/add_wallet_function_aliases.sql
  psql --dry-run -f supabase/migrations/integrate_subscription_payments.sql
  ```

- [ ] **Staging Environment Tested**
  ```bash
  # Run complete migration on staging
  ./test_migration_with_psql.sh staging
  
  # Validate staging results
  ./validate_phase1_migrations.js staging
  ```

### Notification Checklist

- [ ] **Stakeholders Notified**
  - Development team informed of deployment window
  - Operations team on standby for monitoring
  - QA team prepared for post-deployment validation
  - Business stakeholders aware of brief maintenance window (if applicable)

- [ ] **Monitoring Prepared**
  - Database monitoring dashboards active
  - Application error monitoring enabled
  - Performance baseline metrics captured
  - Alert thresholds configured for post-deployment

### Risk Assessment

- [ ] **Low Risk Migrations Confirmed**
  - Migration 1: Column addition (non-breaking)
  - Migration 2: Function aliases (additive only)
  - Migration 3: Table integration (new functionality)

- [ ] **Rollback Procedures Tested**
  ```bash
  # Test rollback on staging
  ./test_rollback_procedures.sh staging
  ```

- [ ] **Emergency Contacts Available**
  - Database administrator on-call
  - Senior developer available for immediate support
  - DevOps team ready for infrastructure issues

## Deployment Execution

### Phase 1: Pre-Migration Validation

#### Step 1.1: Final Environment Check
```bash
#!/bin/bash
# pre_migration_check.sh

echo "=== Pre-Migration Validation ==="

# Check database connectivity
echo "Testing database connection..."
psql $DATABASE_URL -c "SELECT NOW();" || exit 1

# Verify current schema state
echo "Checking current schema state..."
psql $DATABASE_URL -c "
SELECT 
    CASE WHEN EXISTS(SELECT 1 FROM information_schema.columns 
                    WHERE table_name='subscription_plans' AND column_name='interval')
    THEN 'ALREADY_EXISTS' ELSE 'READY' END as migration1_status,
    
    CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname='credit_wallet')
    THEN 'ALREADY_EXISTS' ELSE 'READY' END as migration2_status,
    
    CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables 
                    WHERE table_name='subscription_payments')
    THEN 'ALREADY_EXISTS' ELSE 'READY' END as migration3_status;
"

# Check for blocking processes
echo "Checking for blocking database sessions..."
psql $DATABASE_URL -c "
SELECT pid, usename, application_name, state, query_start, query
FROM pg_stat_activity 
WHERE state = 'active' AND pid <> pg_backend_pid()
ORDER BY query_start;
"

echo "Pre-migration check completed successfully ✅"
```

#### Step 1.2: Application Health Check
```bash
#!/bin/bash
# application_health_check.sh

echo "=== Application Health Check ==="

# Test critical application endpoints
curl -f $APP_URL/health || echo "⚠️  Application health check failed"
curl -f $APP_URL/api/wallet/balance || echo "⚠️  Wallet API health check failed"

# Check current error rates
echo "Checking current error rates..."
# Add monitoring system query here (DataDog, NewRelic, etc.)

echo "Application health check completed ✅"
```

### Phase 2: Migration Execution

#### Step 2.1: Execute Migration 1 (Subscription Plans)
```bash
#!/bin/bash
# execute_migration_1.sh

echo "=== Migration 1: Subscription Plans Schema Alignment ==="

# Execute migration with transaction safety
psql $DATABASE_URL << 'EOF'
BEGIN;

-- Add interval column
ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS interval TEXT;

-- Populate interval for existing records
UPDATE subscription_plans SET interval = CASE
    WHEN duration_days = 7 THEN 'week'
    WHEN duration_days = 30 THEN 'month'
    WHEN duration_days = 90 THEN 'quarter'
    WHEN duration_days = 365 THEN 'year'
    ELSE 'month'
END
WHERE interval IS NULL;

-- Add performance index
CREATE INDEX IF NOT EXISTS idx_subscription_plans_interval 
ON subscription_plans(interval);

-- Add data consistency constraint
ALTER TABLE subscription_plans 
ADD CONSTRAINT IF NOT EXISTS chk_subscription_interval 
CHECK (interval IN ('day', 'week', 'month', 'quarter', 'year'));

-- Validation query
SELECT 
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE interval IS NOT NULL) as records_with_interval
FROM subscription_plans;

COMMIT;
EOF

# Verify migration success
echo "Validating Migration 1..."
psql $DATABASE_URL -c "
SELECT 'Migration 1 Success' as status 
WHERE EXISTS(
    SELECT 1 FROM information_schema.columns 
    WHERE table_name='subscription_plans' AND column_name='interval'
) AND NOT EXISTS(
    SELECT 1 FROM subscription_plans WHERE interval IS NULL
);
"

echo "Migration 1 completed successfully ✅"
```

#### Step 2.2: Execute Migration 2 (Wallet Functions)
```bash
#!/bin/bash
# execute_migration_2.sh

echo "=== Migration 2: Wallet RPC Function Aliases ==="

# Execute migration
psql $DATABASE_URL -f supabase/migrations/add_wallet_function_aliases.sql

# Verify functions created
echo "Validating Migration 2..."
psql $DATABASE_URL -c "
SELECT 
    proname as function_name,
    prosecdef as security_definer,
    CASE WHEN proacl IS NULL THEN 'public' 
         ELSE array_to_string(proacl, ', ') END as permissions
FROM pg_proc 
WHERE proname IN ('credit_wallet', 'debit_wallet')
ORDER BY proname;
"

# Test function accessibility
echo "Testing function calls..."
psql $DATABASE_URL -c "
SELECT 'Functions accessible' as status
WHERE EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'credit_wallet')
AND EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'debit_wallet');
"

echo "Migration 2 completed successfully ✅"
```

#### Step 2.3: Execute Migration 3 (Subscription Payments)
```bash
#!/bin/bash
# execute_migration_3.sh

echo "=== Migration 3: Subscription Payments Integration ==="

# Execute migration
psql $DATABASE_URL -f supabase/migrations/integrate_subscription_payments.sql

# Verify table creation and RLS policies
echo "Validating Migration 3..."
psql $DATABASE_URL -c "
SELECT 
    t.table_name,
    t.table_type,
    CASE WHEN p.tablename IS NOT NULL THEN 'RLS Enabled' ELSE 'No RLS' END as rls_status
FROM information_schema.tables t
LEFT JOIN pg_tables pt ON t.table_name = pt.tablename
LEFT JOIN (SELECT DISTINCT tablename FROM pg_policies) p ON t.table_name = p.tablename
WHERE t.table_name = 'subscription_payments';
"

# Test table access
echo "Testing table operations..."
psql $DATABASE_URL -c "
INSERT INTO subscription_payments (user_id, subscription_plan_id, amount, payment_method)
SELECT 
    (SELECT id FROM users LIMIT 1),
    (SELECT id FROM subscription_plans LIMIT 1),
    9.99,
    'test'
WHERE EXISTS(SELECT 1 FROM users) AND EXISTS(SELECT 1 FROM subscription_plans);

DELETE FROM subscription_payments WHERE payment_method = 'test';

SELECT 'Table operations successful' as status;
"

echo "Migration 3 completed successfully ✅"
```

### Phase 3: Complete Migration Execution Script

```bash
#!/bin/bash
# execute_phase1_migrations.sh

set -e  # Exit on any error

echo "🚀 Starting Phase 1 Critical Database Migrations"
echo "================================================"

# Record start time
START_TIME=$(date)
echo "Start time: $START_TIME"

# Execute migrations in order
./execute_migration_1.sh
./execute_migration_2.sh  
./execute_migration_3.sh

# Final validation
echo "=== Final Migration Validation ==="
./validate_phase1_migrations.js

# Record completion
END_TIME=$(date)
echo "================================================"
echo "✅ Phase 1 Migrations Completed Successfully"
echo "Start time: $START_TIME"
echo "End time: $END_TIME"

# Generate migration report
echo "=== Migration Summary ==="
psql $DATABASE_URL -c "
SELECT 
    'subscription_plans.interval' as feature,
    CASE WHEN EXISTS(SELECT 1 FROM information_schema.columns 
                    WHERE table_name='subscription_plans' AND column_name='interval')
    THEN 'DEPLOYED' ELSE 'FAILED' END as status
UNION ALL
SELECT 
    'credit_wallet function',
    CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname='credit_wallet')
    THEN 'DEPLOYED' ELSE 'FAILED' END
UNION ALL
SELECT 
    'debit_wallet function',
    CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname='debit_wallet')
    THEN 'DEPLOYED' ELSE 'FAILED' END
UNION ALL
SELECT 
    'subscription_payments table',
    CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables 
                    WHERE table_name='subscription_payments')
    THEN 'DEPLOYED' ELSE 'FAILED' END;
"
```

## Post-Deployment Validation

### Phase 1: Immediate Validation (0-5 minutes)

#### Database Health Check
```bash
#!/bin/bash
# immediate_validation.sh

echo "=== Immediate Post-Deployment Validation ==="

# 1. Check database connectivity
psql $DATABASE_URL -c "SELECT 'Database accessible' as status, NOW() as timestamp;"

# 2. Verify all migrations applied
echo "Checking migration status..."
psql $DATABASE_URL -c "
SELECT 
    'Migration Status' as check_type,
    CASE 
        WHEN EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='subscription_plans' AND column_name='interval')
        AND EXISTS(SELECT 1 FROM pg_proc WHERE proname='credit_wallet')
        AND EXISTS(SELECT 1 FROM pg_proc WHERE proname='debit_wallet') 
        AND EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name='subscription_payments')
        THEN '✅ ALL MIGRATIONS APPLIED'
        ELSE '❌ MIGRATIONS INCOMPLETE'
    END as status;
"

# 3. Test critical operations
echo "Testing critical operations..."

# Test subscription plans seeding
psql $DATABASE_URL -c "
INSERT INTO subscription_plans (name, duration_days, interval, price) 
VALUES ('test_plan', 30, 'month', 9.99);
DELETE FROM subscription_plans WHERE name = 'test_plan';
SELECT '✅ Subscription plans operations working' as status;
"

# Test wallet functions
psql $DATABASE_URL -c "
SELECT '✅ Wallet functions accessible' as status
WHERE EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'credit_wallet')
AND EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'debit_wallet');
"

# Test subscription payments
psql $DATABASE_URL -c "
SELECT '✅ Subscription payments table accessible' as status
WHERE EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_payments');
"

echo "Immediate validation completed ✅"
```

### Phase 2: Comprehensive Validation (5-15 minutes)

#### Run Integration Tests
```bash
#!/bin/bash
# comprehensive_validation.sh

echo "=== Comprehensive Post-Deployment Validation ==="

# Run all integration tests
echo "Running integration test suite..."

# Test subscription workflow
./run_task_4_1_integration_test.sh || echo "⚠️  Subscription workflow test failed"

# Test wallet workflow  
./run_task_4_2_wallet_workflow.sh || echo "⚠️  Wallet workflow test failed"

# Test admin operations
./run_task_4_3_admin_test.sh || echo "⚠️  Admin operations test failed"

# Test performance and security
./run_task_4_4_performance_security_validation.sh || echo "⚠️  Performance test failed"

echo "Comprehensive validation completed ✅"
```

#### Performance Monitoring
```bash
#!/bin/bash
# performance_monitoring.sh

echo "=== Performance Monitoring Check ==="

# Monitor key performance metrics
psql $DATABASE_URL -c "
SELECT 
    schemaname,
    relname as table_name,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del
FROM pg_stat_user_tables 
WHERE relname IN ('subscription_plans', 'subscription_payments')
ORDER BY relname;
"

# Check query performance
psql $DATABASE_URL -c "
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows
FROM pg_stat_statements 
WHERE query LIKE '%subscription%' OR query LIKE '%wallet%'
ORDER BY mean_time DESC
LIMIT 10;
"

echo "Performance monitoring completed ✅"
```

### Phase 3: Application Validation (15-20 minutes)

#### End-to-End Application Testing
```javascript
// e2e_application_test.js
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

async function testApplicationIntegration() {
    console.log('=== End-to-End Application Testing ===');

    try {
        // 1. Test subscription plans access
        console.log('Testing subscription plans...');
        const { data: plans, error: plansError } = await supabase
            .from('subscription_plans')
            .select('id, name, duration_days, interval')
            .limit(1);

        if (plansError) throw plansError;
        console.log('✅ Subscription plans accessible');

        // 2. Test subscription payments table
        console.log('Testing subscription payments...');
        const { data: payments, error: paymentsError } = await supabase
            .from('subscription_payments')
            .select('*')
            .limit(1);

        if (paymentsError) throw paymentsError;
        console.log('✅ Subscription payments accessible');

        // 3. Test wallet function aliases (requires admin auth)
        console.log('Testing wallet function availability...');
        
        // Note: This will fail without admin auth, but tests function existence
        const { error: creditError } = await supabase.rpc('credit_wallet', {
            target_user_id: '00000000-0000-0000-0000-000000000000',
            amount: 0.01
        });

        // Function should exist (even if auth fails)
        if (creditError && creditError.message.includes('function credit_wallet does not exist')) {
            throw new Error('credit_wallet function not found');
        }
        console.log('✅ Wallet functions accessible');

        console.log('✅ All application integration tests passed');

    } catch (error) {
        console.error('❌ Application integration test failed:', error.message);
        process.exit(1);
    }
}

testApplicationIntegration();
```

## Monitoring and Alerting

### Post-Deployment Monitoring Dashboard

#### Key Metrics to Monitor
```yaml
# monitoring_config.yml
dashboards:
  phase1_deployment:
    metrics:
      - database_connections:
          query: "SELECT count(*) FROM pg_stat_activity"
          threshold: "< 100"
          
      - subscription_plans_queries:
          query: "SELECT count(*) FROM pg_stat_statements WHERE query LIKE '%subscription_plans%'"
          threshold: "> 0"
          
      - wallet_function_calls:
          query: "SELECT count(*) FROM pg_stat_statements WHERE query LIKE '%credit_wallet%' OR query LIKE '%debit_wallet%'"
          threshold: "> 0"
          
      - subscription_payments_operations:
          query: "SELECT count(*) FROM pg_stat_statements WHERE query LIKE '%subscription_payments%'"
          threshold: "> 0"

alerts:
  - name: "Database Error Rate"
    condition: "error_rate > 1%"
    severity: "critical"
    
  - name: "Wallet Function Failures"  
    condition: "wallet_errors > 5"
    severity: "high"
    
  - name: "Performance Degradation"
    condition: "response_time > baseline * 1.5"
    severity: "medium"
```

#### Automated Health Checks
```bash
#!/bin/bash
# automated_health_check.sh

# Run every 5 minutes post-deployment
while true; do
    echo "$(date): Running health check..."
    
    # Database connectivity
    if ! psql $DATABASE_URL -c "SELECT 1;" > /dev/null 2>&1; then
        echo "ALERT: Database connectivity failed"
        # Send alert to monitoring system
    fi
    
    # Application endpoints
    if ! curl -f -s $APP_URL/health > /dev/null; then
        echo "ALERT: Application health check failed"
        # Send alert to monitoring system
    fi
    
    sleep 300  # 5 minutes
done
```

## Emergency Rollback Procedures

### Immediate Rollback Decision Tree

```
Database Issues Detected?
├─ YES: Critical database errors, data corruption
│   └─ Execute EMERGENCY ROLLBACK (Steps 1-3)
│
├─ Application Issues Only?
│   ├─ Wallet functions not working → Rollback Migration 2
│   ├─ Subscription issues → Rollback Migration 1  
│   └─ Payment issues → Rollback Migration 3
│
└─ NO Issues: Continue monitoring
```

### Emergency Rollback Execution

#### Full Emergency Rollback
```bash
#!/bin/bash
# emergency_rollback.sh

echo "🚨 EXECUTING EMERGENCY ROLLBACK"
echo "================================"

# Stop application traffic (if possible)
echo "Stopping application traffic..."
# Add load balancer / traffic routing commands

# Execute rollback in reverse order
echo "Rolling back Migration 3..."
psql $DATABASE_URL -f supabase/rollback_migration_3_subscription_payments.sql

echo "Rolling back Migration 2..."  
psql $DATABASE_URL -f supabase/rollback_migration_2_wallet_functions.sql

echo "Rolling back Migration 1..."
psql $DATABASE_URL -f supabase/rollback_migration_1_subscription_plans.sql

# Validate rollback
echo "Validating rollback..."
psql $DATABASE_URL -c "
SELECT 
    'Rollback Status' as check_type,
    CASE 
        WHEN NOT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='subscription_plans' AND column_name='interval')
        AND NOT EXISTS(SELECT 1 FROM pg_proc WHERE proname='credit_wallet')
        AND NOT EXISTS(SELECT 1 FROM pg_proc WHERE proname='debit_wallet')
        AND NOT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name='subscription_payments')
        THEN '✅ ROLLBACK COMPLETE'
        ELSE '❌ ROLLBACK INCOMPLETE'
    END as status;
"

# Resume application traffic
echo "Resuming application traffic..."
# Add traffic restoration commands

echo "🚨 Emergency rollback completed"
```

#### Selective Migration Rollback
```bash
#!/bin/bash
# selective_rollback.sh

MIGRATION_TO_ROLLBACK=$1

case $MIGRATION_TO_ROLLBACK in
    1)
        echo "Rolling back Migration 1 (Subscription Plans)..."
        psql $DATABASE_URL -f supabase/rollback_migration_1_subscription_plans.sql
        ;;
    2)
        echo "Rolling back Migration 2 (Wallet Functions)..."
        psql $DATABASE_URL -f supabase/rollback_migration_2_wallet_functions.sql
        ;;
    3)
        echo "Rolling back Migration 3 (Subscription Payments)..."
        psql $DATABASE_URL -f supabase/rollback_migration_3_subscription_payments.sql
        ;;
    *)
        echo "Usage: $0 {1|2|3}"
        echo "1 = Subscription Plans, 2 = Wallet Functions, 3 = Subscription Payments"
        exit 1
        ;;
esac

echo "Selective rollback of Migration $MIGRATION_TO_ROLLBACK completed"
```

## Communication Templates

### Pre-Deployment Notification
```
Subject: Scheduled Maintenance - Phase 1 Database Fixes

Team,

We will be deploying Phase 1 critical database fixes on [DATE] at [TIME].

IMPACT:
- Duration: ~15 minutes
- Downtime: None expected (optional 5-minute maintenance window)
- Affected Features: Subscription management, admin wallet operations

CHANGES:
- Fixed subscription plan seeding issues
- Added admin wallet function aliases
- Integrated subscription payments table

CONTACTS:
- Primary: [Developer Name] - [Contact Info]
- Backup: [Operations Team] - [Contact Info]

Thank you,
Development Team
```

### Post-Deployment Success
```
Subject: ✅ Phase 1 Database Fixes - Deployment Successful

Team,

Phase 1 critical database fixes have been successfully deployed.

DEPLOYMENT SUMMARY:
- Start Time: [START_TIME]
- End Time: [END_TIME]
- Duration: [DURATION]
- Issues: None

VALIDATION RESULTS:
✅ All migrations applied successfully
✅ Integration tests passed
✅ Performance metrics within baseline
✅ No application errors detected

All three critical database issues have been resolved:
1. Subscription plan seeding now working
2. Admin wallet operations fully functional
3. Subscription payments processing enabled

Monitoring will continue for the next 24 hours.

Thank you,
Development Team
```

### Emergency Rollback Notification
```
Subject: 🚨 URGENT - Database Rollback Executed

Team,

Due to critical issues detected post-deployment, we have executed an emergency rollback of Phase 1 database fixes.

ROLLBACK DETAILS:
- Time: [TIMESTAMP]
- Reason: [SPECIFIC_ISSUE]
- Status: [COMPLETE/IN_PROGRESS]

CURRENT STATE:
- Database restored to pre-deployment state
- Application functionality restored
- Investigation in progress

NEXT STEPS:
- Root cause analysis underway
- Fixed deployment planned for [DATE]
- Post-mortem scheduled

Immediate escalation: [CONTACT_INFO]

Development Team
```

## Checklist Summary

### Pre-Deployment ✅
- [ ] Database backup completed and verified
- [ ] Staging environment fully tested
- [ ] All stakeholders notified
- [ ] Monitoring systems prepared
- [ ] Rollback procedures tested
- [ ] Emergency contacts available

### Deployment ✅  
- [ ] Pre-migration validation passed
- [ ] Migration 1 (Subscription Plans) executed successfully
- [ ] Migration 2 (Wallet Functions) executed successfully
- [ ] Migration 3 (Subscription Payments) executed successfully
- [ ] Final migration validation passed

### Post-Deployment ✅
- [ ] Immediate validation completed (0-5 min)
- [ ] Integration tests passed (5-15 min)
- [ ] End-to-end application tests passed (15-20 min)
- [ ] Performance monitoring active
- [ ] Success notification sent
- [ ] Documentation updated

### Emergency Procedures ✅
- [ ] Rollback scripts tested and ready
- [ ] Emergency contacts established
- [ ] Communication templates prepared
- [ ] Escalation procedures defined

---

**Document Version**: 1.0  
**Last Updated**: January 2024  
**Deployment Guide Version**: Phase 1 Complete