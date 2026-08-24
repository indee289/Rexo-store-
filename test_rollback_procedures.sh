#!/bin/bash

# ============================================================================
# ROLLBACK TESTING SCRIPT - Phase 1 Critical Database Fixes
# ============================================================================
# PURPOSE: Test all rollback scripts to ensure they work correctly
# 
# USAGE: ./test_rollback_procedures.sh [OPTIONS]
#
# OPTIONS:
#   --test-individual    Test individual migration rollbacks
#   --test-complete      Test complete Phase 1 rollback  
#   --test-recovery      Test recovery procedures after rollback
#   --dry-run           Show commands without executing
#   --help              Show this help message
#
# PREREQUISITES:
#   - PostgreSQL/Supabase database access configured
#   - psql command line tool available
#   - Database with Phase 1 migrations applied
#   - Backup of test database (recommended)
#
# SAFETY WARNINGS:
#   ⚠️  This script modifies database schema and data
#   ⚠️  Run on test/staging environment only - NEVER on production
#   ⚠️  Ensure database backup exists before testing
#   ⚠️  Each test may leave database in different state
# ============================================================================

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUPABASE_DIR="${SCRIPT_DIR}/supabase"
TEST_LOG="${SCRIPT_DIR}/rollback_test_results.log"
DRY_RUN=false
VERBOSE=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${timestamp}]${NC} $message" | tee -a "$TEST_LOG"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}✅ SUCCESS:${NC} $message" | tee -a "$TEST_LOG"
}

log_error() {
    local message="$1"
    echo -e "${RED}❌ ERROR:${NC} $message" | tee -a "$TEST_LOG"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠️  WARNING:${NC} $message" | tee -a "$TEST_LOG"
}

execute_sql() {
    local sql_file="$1"
    local description="$2"
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Would execute $sql_file ($description)"
        return 0
    fi
    
    log "Executing: $description"
    log "SQL File: $sql_file"
    
    if [ ! -f "$sql_file" ]; then
        log_error "SQL file not found: $sql_file"
        return 1
    fi
    
    # Execute SQL and capture both stdout and stderr
    if psql -f "$sql_file" 2>&1 | tee -a "$TEST_LOG"; then
        log_success "$description completed"
        return 0
    else
        log_error "$description failed"
        return 1
    fi
}

check_database_connection() {
    log "Testing database connection..."
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Would test database connection"
        return 0
    fi
    
    if psql -c "SELECT version();" > /dev/null 2>&1; then
        log_success "Database connection successful"
        return 0
    else
        log_error "Database connection failed"
        log_error "Ensure PGUSER, PGDATABASE, PGHOST, PGPORT environment variables are set"
        return 1
    fi
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

validate_phase1_applied() {
    log "Validating Phase 1 migrations are applied..."
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Would validate Phase 1 migrations"
        return 0
    fi
    
    local validation_sql="
    SELECT 
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_payments') 
             THEN 'YES' ELSE 'NO' END as subscription_payments_table,
        CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'credit_wallet') 
             THEN 'YES' ELSE 'NO' END as credit_wallet_function,
        CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'debit_wallet') 
             THEN 'YES' ELSE 'NO' END as debit_wallet_function,
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plans' AND column_name = 'interval') 
             THEN 'YES' ELSE 'NO' END as interval_column;
    "
    
    log "Phase 1 Migration Status:"
    psql -c "$validation_sql" | tee -a "$TEST_LOG"
}

validate_rollback_success() {
    local rollback_type="$1"
    
    log "Validating $rollback_type rollback success..."
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Would validate rollback success"
        return 0
    fi
    
    local validation_sql="
    SELECT 
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'subscription_payments') 
             THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as subscription_payments_table,
        CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'credit_wallet') 
             THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as credit_wallet_function,
        CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'debit_wallet') 
             THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as debit_wallet_function,
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'subscription_plans' AND column_name = 'interval') 
             THEN 'STILL EXISTS' ELSE 'ROLLED BACK' END as interval_column;
    "
    
    log "$rollback_type Rollback Status:"
    psql -c "$validation_sql" | tee -a "$TEST_LOG"
}

validate_core_functionality() {
    log "Validating core functionality preserved..."
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN: Would validate core functionality"
        return 0
    fi
    
    local validation_sql="
    SELECT 
        COUNT(*) as subscription_plans_count,
        CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'increment_wallet_balance') 
             THEN 'EXISTS' ELSE 'MISSING' END as increment_function,
        CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'decrement_wallet_balance') 
             THEN 'EXISTS' ELSE 'MISSING' END as decrement_function
    FROM public.subscription_plans;
    "
    
    log "Core Functionality Status:"
    psql -c "$validation_sql" | tee -a "$TEST_LOG"
}

# ============================================================================
# TEST FUNCTIONS
# ============================================================================

test_individual_rollback_migration_1() {
    log "============================================================================"
    log "TESTING: Individual Rollback - Migration 1 (Subscription Plans Schema)"
    log "============================================================================"
    
    validate_phase1_applied
    
    execute_sql "${SUPABASE_DIR}/rollback_migration_1_subscription_plans.sql" \
                "Migration 1 Rollback (Subscription Plans Schema)"
    
    validate_rollback_success "Migration 1"
    validate_core_functionality
    
    log_success "Migration 1 rollback test completed"
}

test_individual_rollback_migration_2() {
    log "============================================================================"
    log "TESTING: Individual Rollback - Migration 2 (Wallet Function Aliases)"
    log "============================================================================"
    
    validate_phase1_applied
    
    execute_sql "${SUPABASE_DIR}/rollback_migration_2_wallet_functions.sql" \
                "Migration 2 Rollback (Wallet Function Aliases)"
    
    validate_rollback_success "Migration 2"
    validate_core_functionality
    
    log_success "Migration 2 rollback test completed"
}

test_individual_rollback_migration_3() {
    log "============================================================================"
    log "TESTING: Individual Rollback - Migration 3 (Subscription Payments Table)"
    log "============================================================================"
    
    validate_phase1_applied
    
    execute_sql "${SUPABASE_DIR}/rollback_migration_3_subscription_payments.sql" \
                "Migration 3 Rollback (Subscription Payments Table)"
    
    validate_rollback_success "Migration 3"
    validate_core_functionality
    
    log_success "Migration 3 rollback test completed"
}

test_complete_rollback() {
    log "============================================================================"
    log "TESTING: Complete Phase 1 Rollback (All Migrations)"
    log "============================================================================"
    
    validate_phase1_applied
    
    execute_sql "${SUPABASE_DIR}/rollback_complete_phase1.sql" \
                "Complete Phase 1 Rollback (All Migrations)"
    
    validate_rollback_success "Complete Phase 1"
    validate_core_functionality
    
    # Test that backup table was created
    if [ "$DRY_RUN" = false ]; then
        log "Checking backup table creation..."
        psql -c "SELECT COUNT(*) as backup_records FROM subscription_payments_rollback_backup;" | tee -a "$TEST_LOG" || {
            log_warning "Backup table not found - may be expected if Migration 3 was not applied"
        }
    fi
    
    log_success "Complete Phase 1 rollback test completed"
}

test_recovery_procedures() {
    log "============================================================================"
    log "TESTING: Recovery Procedures (Re-apply migrations after rollback)"
    log "============================================================================"
    
    # Validate that rollback was successful first
    validate_rollback_success "Pre-Recovery"
    
    # Re-apply migrations in correct order
    execute_sql "${SUPABASE_DIR}/fix_subscription_plans_schema.sql" \
                "Recovery - Re-apply Migration 1"
    
    execute_sql "${SUPABASE_DIR}/migrations/add_wallet_function_aliases.sql" \
                "Recovery - Re-apply Migration 2"
    
    execute_sql "${SUPABASE_DIR}/migrations/integrate_subscription_payments.sql" \
                "Recovery - Re-apply Migration 3"
    
    # Validate Phase 1 is fully restored
    validate_phase1_applied
    validate_core_functionality
    
    log_success "Recovery procedure test completed"
}

# ============================================================================
# ERROR TESTING FUNCTIONS
# ============================================================================

test_rollback_error_handling() {
    log "============================================================================"
    log "TESTING: Rollback Error Handling (Edge Cases)"
    log "============================================================================"
    
    # Test rollback when migrations are not applied
    log "Testing rollback on non-applied migrations..."
    
    if [ "$DRY_RUN" = false ]; then
        # This should not cause errors, just warnings
        execute_sql "${SUPABASE_DIR}/rollback_migration_1_subscription_plans.sql" \
                    "Rollback Migration 1 (possibly not applied)" || {
            log_warning "Rollback failed - this may be expected if migration not applied"
        }
    fi
    
    log_success "Error handling test completed"
}

# ============================================================================
# MAIN TEST ORCHESTRATION
# ============================================================================

run_all_tests() {
    log "============================================================================"
    log "STARTING COMPREHENSIVE ROLLBACK TESTING"
    log "============================================================================"
    
    check_database_connection || exit 1
    
    # Test individual rollbacks
    log "\n🧪 PHASE 1: Testing Individual Migration Rollbacks"
    test_individual_rollback_migration_1
    test_individual_rollback_migration_2  
    test_individual_rollback_migration_3
    
    # Test complete rollback
    log "\n🧪 PHASE 2: Testing Complete Phase 1 Rollback"
    test_complete_rollback
    
    # Test recovery procedures
    log "\n🧪 PHASE 3: Testing Recovery Procedures"
    test_recovery_procedures
    
    # Test error handling
    log "\n🧪 PHASE 4: Testing Error Handling"
    test_rollback_error_handling
    
    log "============================================================================"
    log "ROLLBACK TESTING COMPLETED SUCCESSFULLY"
    log "============================================================================"
    log "Test results saved to: $TEST_LOG"
}

# ============================================================================
# COMMAND LINE INTERFACE
# ============================================================================

show_help() {
    cat << EOF
ROLLBACK TESTING SCRIPT - Phase 1 Critical Database Fixes

USAGE: $0 [OPTIONS]

OPTIONS:
    --test-individual     Test individual migration rollbacks only
    --test-complete       Test complete Phase 1 rollback only
    --test-recovery       Test recovery procedures only
    --test-all           Run all tests (default)
    --dry-run            Show commands without executing
    --help               Show this help message

EXAMPLES:
    $0 --test-complete                    # Test complete rollback
    $0 --test-individual --dry-run        # Dry run individual tests
    $0 --test-recovery                    # Test recovery only

ENVIRONMENT VARIABLES:
    PGUSER               PostgreSQL username
    PGDATABASE           PostgreSQL database name
    PGHOST               PostgreSQL host (default: localhost)
    PGPORT               PostgreSQL port (default: 5432)
    PGPASSWORD           PostgreSQL password

SAFETY NOTES:
    ⚠️  Run on test/staging environment ONLY
    ⚠️  Ensure database backup exists before testing
    ⚠️  Each test may modify database schema and data

EOF
}

# Initialize test log
echo "ROLLBACK TESTING STARTED at $(date)" > "$TEST_LOG"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --test-individual)
            check_database_connection || exit 1
            test_individual_rollback_migration_1
            test_individual_rollback_migration_2
            test_individual_rollback_migration_3
            exit 0
            ;;
        --test-complete)
            check_database_connection || exit 1
            test_complete_rollback
            exit 0
            ;;
        --test-recovery)
            check_database_connection || exit 1
            test_recovery_procedures
            exit 0
            ;;
        --test-all)
            run_all_tests
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            log "DRY RUN MODE ENABLED - No database changes will be made"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

# Default action if no arguments provided
log "No specific test selected, running all tests..."
run_all_tests

# ============================================================================
# END OF SCRIPT
# ============================================================================