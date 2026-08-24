# Phase 1 Critical Fixes - Rollback Procedures Documentation

## Overview

This document provides comprehensive guidance for safely rolling back the Phase 1 critical database fixes in the Rexo Marketplace application. The rollback procedures are designed to restore the database to its pre-fix state while preserving all critical user data and core functionality.

## Table of Contents

1. [Rollback Overview](#rollback-overview)
2. [Safety Guidelines](#safety-guidelines)
3. [Individual Migration Rollbacks](#individual-migration-rollbacks)
4. [Complete Phase 1 Rollback](#complete-phase-1-rollback)
5. [Testing Procedures](#testing-procedures)
6. [Recovery Options](#recovery-options)
7. [Application Updates Required](#application-updates-required)
8. [Troubleshooting Guide](#troubleshooting-guide)

## Rollback Overview

### Phase 1 Migrations Applied
The following migrations were applied during Phase 1 and can be rolled back:

| Migration | File | Purpose | Rollback Risk |
|-----------|------|---------|---------------|
| **Migration 1** | `fix_subscription_plans_schema.sql` | Added `interval` column to subscription_plans table | **LOW** - Only removes added column |
| **Migration 2** | `add_wallet_function_aliases.sql` | Added `credit_wallet` and `debit_wallet` function aliases | **LOW** - Only removes function aliases |
| **Migration 3** | `integrate_subscription_payments.sql` | Added `subscription_payments` table with full schema | **HIGH** - Removes table and all data |

### Rollback Execution Order
Rollbacks must be executed in **reverse order** of application:
```
Migration 3 (Subscription Payments) → Migration 2 (Wallet Functions) → Migration 1 (Subscription Plans)
```

## Safety Guidelines

### ⚠️ Critical Safety Requirements

1. **NEVER execute rollbacks on production without full database backup**
2. **Test all rollback procedures on staging environment first**
3. **Coordinate rollback with application deployment team**
4. **Schedule rollback during maintenance window for high-risk changes**
5. **Have rollback recovery plan ready before execution**

### Pre-Rollback Checklist

- [ ] **Complete database backup created and verified**
- [ ] **Staging environment testing completed successfully**
- [ ] **Application team notified and prepared for changes**
- [ ] **Rollback tested on copy of production data**
- [ ] **Recovery procedures tested and validated**
- [ ] **Maintenance window scheduled (if needed)**
- [ ] **Monitoring and alerting systems prepared**

### Risk Assessment by Migration

| Migration | Data Loss Risk | Functionality Impact | Recovery Difficulty |
|-----------|----------------|---------------------|-------------------|
| **Migration 1** | None | Low (seeding fails) | Easy |
| **Migration 2** | None | Medium (admin functions fail) | Easy |
| **Migration 3** | **HIGH** | High (payments disabled) | **Difficult** |

## Individual Migration Rollbacks

### Migration 1 Rollback: Subscription Plans Schema

**Purpose**: Remove `interval` column added for seed script compatibility

**Risk Level**: 🟢 **LOW RISK**

**Execute:**
```bash
psql -f supabase/rollback_migration_1_subscription_plans.sql
```

**Impact:**
- ✅ All subscription plan data preserved (`duration_days` column intact)
- ✅ All user subscriptions continue working
- ❌ `seed_subscription_plans.sql` will fail with "column interval does not exist"

**Recovery:** Re-run `fix_subscription_plans_schema.sql`

### Migration 2 Rollback: Wallet Function Aliases

**Purpose**: Remove `credit_wallet` and `debit_wallet` function aliases

**Risk Level**: 🟡 **MEDIUM RISK**

**Execute:**
```bash
psql -f supabase/rollback_migration_2_wallet_functions.sql
```

**Impact:**
- ✅ All wallet data and balances preserved
- ✅ Original functions (`increment_wallet_balance`, `decrement_wallet_balance`) continue working
- ❌ Admin deposit/withdrawal approvals via `credit_wallet`/`debit_wallet` will fail
- ❌ Applications calling alias functions need immediate updates

**Recovery:** Re-run `migrations/add_wallet_function_aliases.sql`

### Migration 3 Rollback: Subscription Payments Table

**Purpose**: Remove `subscription_payments` table and all related components

**Risk Level**: 🔴 **HIGH RISK - DATA LOSS**

**Execute:**
```bash
psql -f supabase/rollback_migration_3_subscription_payments.sql
```

**Impact:**
- ⚠️ **ALL subscription payment data will be permanently lost**
- ⚠️ Subscription payment workflow completely disabled
- ❌ Users cannot submit subscription payments
- ❌ Admin cannot review/approve subscription payments
- ✅ Automatic backup table created: `subscription_payments_rollback_backup`
- ✅ Other subscription functionality preserved

**Recovery:** Re-run `migrations/integrate_subscription_payments.sql` and restore from backup

## Complete Phase 1 Rollback

### Execute Complete Rollback

**Purpose**: Roll back all Phase 1 migrations in single atomic operation

**Risk Level**: 🔴 **HIGH RISK - COMPREHENSIVE CHANGES**

**Execute:**
```bash
psql -f supabase/rollback_complete_phase1.sql
```

**Impact Summary:**
- ❌ Subscription payment workflow **DISABLED**
- ❌ Admin wallet functions via `credit_wallet`/`debit_wallet` **FAIL**
- ❌ Subscription plan seeding via `seed_subscription_plans.sql` **FAILS**
- ✅ All user data, wallet balances, and core functionality **PRESERVED**

### Post-Rollback Verification

After complete rollback, verify success:

```sql
-- Verify all Phase 1 changes are rolled back
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_payments') 
         THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as subscription_payments_table,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'credit_wallet') 
         THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as credit_wallet_function,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'debit_wallet') 
         THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as debit_wallet_function,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plans' AND column_name = 'interval') 
         THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as interval_column;

-- Verify core functionality preserved
SELECT 
    COUNT(*) as subscription_plans_count,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'increment_wallet_balance') 
         THEN 'EXISTS' ELSE 'MISSING' END as increment_function,
    CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'decrement_wallet_balance') 
         THEN 'EXISTS' ELSE 'MISSING' END as decrement_function
FROM public.subscription_plans;
```

## Testing Procedures

### Automated Testing Script

Use the provided testing script to validate rollback procedures:

```bash
# Test individual rollbacks
./test_rollback_procedures.sh --test-individual

# Test complete rollback
./test_rollback_procedures.sh --test-complete

# Test recovery procedures
./test_rollback_procedures.sh --test-recovery

# Dry run (no database changes)
./test_rollback_procedures.sh --dry-run
```

### Manual Testing Checklist

After rollback execution:

- [ ] **Database Connection**: Verify database is accessible and responding
- [ ] **Core Tables**: Confirm critical tables (`users`, `subscription_plans`) exist and contain data
- [ ] **Original Functions**: Test `increment_wallet_balance` and `decrement_wallet_balance` work
- [ ] **Rolled Back Features**: Confirm rolled back functionality fails as expected
- [ ] **Application Startup**: Verify application starts without database errors
- [ ] **User Authentication**: Test login/logout functionality
- [ ] **Subscription Plans**: Test subscription plan display and selection

## Recovery Options

### Complete Recovery (Re-apply All Migrations)

To fully restore Phase 1 fixes after rollback:

```bash
# Step 1: Re-apply migrations in original order
psql -f supabase/fix_subscription_plans_schema.sql
psql -f supabase/migrations/add_wallet_function_aliases.sql  
psql -f supabase/migrations/integrate_subscription_payments.sql

# Step 2: Restore subscription payment data (if Migration 3 was rolled back)
psql -c "
INSERT INTO public.subscription_payments 
(id, user_id, plan_id, plan_name, amount, duration_days, payment_method, 
 transaction_ref, proof_url, status, admin_notes, created_at, processed_at)
SELECT id, user_id, plan_id, plan_name, amount, duration_days, payment_method,
       transaction_ref, proof_url, status, admin_notes, created_at, processed_at
FROM subscription_payments_rollback_backup;
"

# Step 3: Clean up backup table
psql -c "DROP TABLE subscription_payments_rollback_backup;"

# Step 4: Verify complete recovery
psql -c "SELECT COUNT(*) FROM subscription_payments;"
psql -f supabase/seed_subscription_plans.sql
```

### Partial Recovery (Individual Migrations)

Restore specific migrations as needed:

```bash
# Restore only subscription plans schema (Migration 1)
psql -f supabase/fix_subscription_plans_schema.sql

# Restore only wallet function aliases (Migration 2)  
psql -f supabase/migrations/add_wallet_function_aliases.sql

# Restore only subscription payments table (Migration 3)
psql -f supabase/migrations/integrate_subscription_payments.sql
```

## Application Updates Required

### Flutter Application Changes

After rollback, update Flutter application code:

#### Migration 1 Rollback (Subscription Plans)
- **No code changes required** - application should use `duration_days` column

#### Migration 2 Rollback (Wallet Functions)
- **Update admin wallet operations:**
```dart
// Before (will fail after rollback):
await supabase.rpc('credit_wallet', {'p_user_id': userId, 'p_amount': amount});
await supabase.rpc('debit_wallet', {'p_user_id': userId, 'p_amount': amount});

// After (works with rollback):
await supabase.rpc('increment_wallet_balance', {'p_user_id': userId, 'p_amount': amount});
await supabase.rpc('decrement_wallet_balance', {'p_user_id': userId, 'p_amount': amount});
```

#### Migration 3 Rollback (Subscription Payments)
- **Remove subscription payment UI components**
- **Hide payment method selection**
- **Update subscription flow to use alternative payment methods**
- **Add error handling for missing table operations**
- **Update admin dashboard to remove payment review features**

### API/Backend Changes

- Update error handling for missing functions/tables
- Disable subscription payment endpoints
- Update API documentation
- Remove payment validation logic
- Update monitoring and alerting

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Rollback Script Fails with Permission Error
**Symptoms:** `ERROR: permission denied for table/function`
**Solution:** 
- Ensure database user has sufficient privileges
- Run as database superuser if necessary
- Check RLS policies are not blocking operation

#### Issue: Backup Table Creation Fails
**Symptoms:** `ERROR: relation "subscription_payments" does not exist`
**Solution:**
- This is expected if Migration 3 was not applied
- Rollback will continue without creating backup
- No data loss since table didn't exist

#### Issue: Original Functions Missing After Rollback
**Symptoms:** `ERROR: function increment_wallet_balance does not exist`
**Solution:**
- **CRITICAL:** Do not proceed with application deployment
- Restore from database backup immediately
- Re-apply original wallet function migration
- Contact database administrator

#### Issue: Application Startup Fails After Rollback
**Symptoms:** Database connection errors during app startup
**Solution:**
- Check database connectivity
- Verify core tables exist (`users`, `subscription_plans`)
- Update application configuration if needed
- Review application logs for specific errors

#### Issue: Rollback Appears Successful But Features Still Work
**Symptoms:** Expected failures don't occur after rollback
**Solution:**
- Verify rollback script executed completely
- Check for multiple database environments
- Confirm application is connecting to correct database
- Review rollback transaction logs

### Recovery from Failed Rollback

If rollback fails mid-execution:

1. **Immediate Actions:**
   - Check database connectivity
   - Review error logs in rollback output
   - Do NOT attempt to re-run rollback

2. **Assessment:**
   - Determine which step failed
   - Check database state with validation queries
   - Identify if partial rollback occurred

3. **Recovery Options:**
   - **Option A:** Complete rollback manually (execute remaining steps)
   - **Option B:** Restore from database backup
   - **Option C:** Re-apply migrations to restore functionality

4. **Prevention:**
   - Always test rollback procedures on staging first
   - Use transaction-wrapped rollback scripts
   - Maintain current database backups

### Emergency Contacts

If critical issues occur during rollback:

1. **Database Administrator** - For schema and data issues
2. **Application Team Lead** - For application compatibility issues  
3. **DevOps Team** - For deployment and infrastructure issues
4. **Product Manager** - For business impact decisions

## Best Practices

### Before Rollback
- Document current database state
- Test rollback on staging environment
- Prepare application updates
- Schedule appropriate maintenance window
- Notify all stakeholders

### During Rollback
- Monitor rollback execution closely
- Watch for any errors or warnings
- Verify each step completes successfully
- Document any unexpected behavior
- Have recovery plan ready

### After Rollback  
- Verify rollback success with validation queries
- Test critical application functionality
- Monitor error rates and performance
- Update monitoring and alerting
- Document lessons learned

---

## Appendix: Rollback File Reference

| File | Purpose | Risk Level |
|------|---------|------------|
| `rollback_migration_1_subscription_plans.sql` | Rollback subscription plans schema changes | LOW |
| `rollback_migration_2_wallet_functions.sql` | Rollback wallet function aliases | MEDIUM |
| `rollback_migration_3_subscription_payments.sql` | Rollback subscription payments table | HIGH |
| `rollback_complete_phase1.sql` | Rollback all Phase 1 migrations | HIGH |
| `test_rollback_procedures.sh` | Test rollback procedures safely | N/A |
| `ROLLBACK_PROCEDURES_DOCUMENTATION.md` | This documentation | N/A |

---

*Document Version: 1.0*  
*Last Updated: $(date)*  
*Contact: Database Team*