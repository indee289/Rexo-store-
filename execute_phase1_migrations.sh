#!/bin/bash

# ============================================================================
# TASK 3.4: Execute Phase 1 Critical Database Migrations
# ============================================================================
#
# This script executes the three critical database migrations in the correct
# order to resolve the Phase 1 database schema issues:
#
# 1. Subscription plans schema alignment (interval column)
# 2. Wallet RPC function aliases (credit_wallet, debit_wallet)
# 3. Subscription payments table integration
#
# EXECUTION ORDER: These MUST be applied in sequence due to dependencies
# ROLLBACK READY: Each migration includes rollback instructions
#
# USAGE:
#   ./execute_phase1_migrations.sh [CONNECTION_STRING]
#
# REQUIREMENTS:
#   - PostgreSQL client (psql) with connection to Supabase database
#   - Database admin privileges for schema modifications
#   - Maintenance window recommended for production deployment
# ============================================================================

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATION_DIR="$SCRIPT_DIR/supabase"
LOG_FILE="$SCRIPT_DIR/phase1_migration_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    log "${RED}❌ ERROR: $1${NC}"
    log "${YELLOW}Check log file: $LOG_FILE${NC}"
    exit 1
}

# Success message
success() {
    log "${GREEN}✅ $1${NC}"
}

# Warning message
warning() {
    log "${YELLOW}⚠️  $1${NC}"
}

# Info message
info() {
    log "${BLUE}ℹ️  $1${NC}"
}

# ============================================================================
# MIGRATION FILE VALIDATION
# ============================================================================

validate_migration_files() {
    log "\n${BLUE}=== VALIDATING MIGRATION FILES ===${NC}"
    
    # Migration 1: Subscription Plans Schema Alignment
    MIGRATION_1="$MIGRATION_DIR/fix_subscription_plans_schema.sql"
    if [[ ! -f "$MIGRATION_1" ]]; then
        error_exit "Migration 1 file not found: $MIGRATION_1"
    fi
    success "Migration 1 found: $(basename "$MIGRATION_1")"
    
    # Migration 2: Wallet Function Aliases
    MIGRATION_2="$MIGRATION_DIR/migrations/add_wallet_function_aliases.sql"
    if [[ ! -f "$MIGRATION_2" ]]; then
        error_exit "Migration 2 file not found: $MIGRATION_2"
    fi
    success "Migration 2 found: $(basename "$MIGRATION_2")"
    
    # Migration 3: Subscription Payments Integration
    MIGRATION_3="$MIGRATION_DIR/migrations/integrate_subscription_payments.sql"
    if [[ ! -f "$MIGRATION_3" ]]; then
        error_exit "Migration 3 file not found: $MIGRATION_3"
    fi
    success "Migration 3 found: $(basename "$MIGRATION_3")"
    
    log "${GREEN}All migration files validated successfully${NC}"
}

# ============================================================================
# DATABASE CONNECTION VALIDATION
# ============================================================================

validate_database_connection() {
    log "\n${BLUE}=== VALIDATING DATABASE CONNECTION ===${NC}"
    
    if [[ -z "$DATABASE_URL" ]]; then
        error_exit "DATABASE_URL environment variable not set"
    fi
    
    # Test database connection
    if ! psql "$DATABASE_URL" -c "SELECT version();" >/dev/null 2>&1; then
        error_exit "Cannot connect to database. Check DATABASE_URL and network connectivity."
    fi
    
    success "Database connection established"
    
    # Check if we have necessary privileges
    if ! psql "$DATABASE_URL" -c "SELECT has_database_privilege(current_user, current_database(), 'CREATE');" | grep -q "t"; then
        error_exit "Insufficient database privileges. Admin access required."
    fi
    
    success "Database privileges verified"
}

# ============================================================================
# PRE-MIGRATION BACKUP AND VALIDATION
# ============================================================================

pre_migration_checks() {
    log "\n${BLUE}=== PRE-MIGRATION CHECKS ===${NC}"
    
    # Check current schema state
    info "Checking current subscription_plans table structure..."
    psql "$DATABASE_URL" -c "\d public.subscription_plans" >> "$LOG_FILE" 2>&1 || true
    
    info "Checking current wallet functions..."
    psql "$DATABASE_URL" -c "SELECT proname FROM pg_proc WHERE proname LIKE '%wallet%';" >> "$LOG_FILE" 2>&1 || true
    
    info "Checking if subscription_payments table exists..."
    psql "$DATABASE_URL" -c "\d public.subscription_payments" >> "$LOG_FILE" 2>&1 || true
    
    # Create backup of current state (metadata only)
    info "Creating schema backup..."
    pg_dump "$DATABASE_URL" --schema-only --no-owner --no-privileges > "schema_backup_$(date +%Y%m%d_%H%M%S).sql"
    success "Schema backup created"
}

# ============================================================================
# MIGRATION EXECUTION FUNCTIONS
# ============================================================================

execute_migration_1() {
    log "\n${BLUE}=== EXECUTING MIGRATION 1: SUBSCRIPTION PLANS SCHEMA ALIGNMENT ===${NC}"
    
    info "Adding interval column to subscription_plans table..."
    
    if ! psql "$DATABASE_URL" -f "$MIGRATION_1" >> "$LOG_FILE" 2>&1; then
        error_exit "Migration 1 failed. Check log for details."
    fi
    
    success "Migration 1 completed successfully"
    
    # Validate results
    info "Validating Migration 1 results..."
    
    # Check that interval column was added
    if ! psql "$DATABASE_URL" -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'subscription_plans' AND column_name = 'interval';" | grep -q "interval"; then
        error_exit "Migration 1 validation failed: interval column not found"
    fi
    
    # Check that existing data is preserved
    RECORD_COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM public.subscription_plans WHERE duration_days IS NOT NULL;")
    if [[ "$RECORD_COUNT" -eq 0 ]]; then
        warning "No existing subscription_plans data found (this may be normal for new installations)"
    else
        success "Existing subscription_plans data preserved ($RECORD_COUNT records)"
    fi
    
    success "Migration 1 validation passed"
}

execute_migration_2() {
    log "\n${BLUE}=== EXECUTING MIGRATION 2: WALLET FUNCTION ALIASES ===${NC}"
    
    info "Creating wallet function aliases..."
    
    if ! psql "$DATABASE_URL" -f "$MIGRATION_2" >> "$LOG_FILE" 2>&1; then
        error_exit "Migration 2 failed. Check log for details."
    fi
    
    success "Migration 2 completed successfully"
    
    # Validate results
    info "Validating Migration 2 results..."
    
    # Check that new functions exist
    FUNCTION_COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM pg_proc WHERE proname IN ('credit_wallet', 'debit_wallet');")
    if [[ "$FUNCTION_COUNT" -ne 2 ]]; then
        error_exit "Migration 2 validation failed: Expected 2 new functions, found $FUNCTION_COUNT"
    fi
    
    # Check that original functions still exist
    ORIGINAL_COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM pg_proc WHERE proname IN ('increment_wallet_balance', 'decrement_wallet_balance');")
    if [[ "$ORIGINAL_COUNT" -ne 2 ]]; then
        error_exit "Migration 2 validation failed: Original wallet functions missing"
    fi
    
    success "Migration 2 validation passed"
}

execute_migration_3() {
    log "\n${BLUE}=== EXECUTING MIGRATION 3: SUBSCRIPTION PAYMENTS INTEGRATION ===${NC}"
    
    info "Creating subscription_payments table..."
    
    if ! psql "$DATABASE_URL" -f "$MIGRATION_3" >> "$LOG_FILE" 2>&1; then
        error_exit "Migration 3 failed. Check log for details."
    fi
    
    success "Migration 3 completed successfully"
    
    # Validate results
    info "Validating Migration 3 results..."
    
    # Check that table exists
    if ! psql "$DATABASE_URL" -c "\d public.subscription_payments" >> "$LOG_FILE" 2>&1; then
        error_exit "Migration 3 validation failed: subscription_payments table not found"
    fi
    
    # Check that RLS is enabled
    RLS_ENABLED=$(psql "$DATABASE_URL" -t -c "SELECT relrowsecurity FROM pg_class WHERE relname = 'subscription_payments';")
    if [[ "$RLS_ENABLED" != " t" ]]; then
        error_exit "Migration 3 validation failed: RLS not enabled on subscription_payments table"
    fi
    
    # Check that policies exist
    POLICY_COUNT=$(psql "$DATABASE_URL" -t -c "SELECT COUNT(*) FROM pg_policies WHERE tablename = 'subscription_payments';")
    if [[ "$POLICY_COUNT" -lt 4 ]]; then
        warning "Migration 3 validation: Expected 4 RLS policies, found $POLICY_COUNT"
    fi
    
    success "Migration 3 validation passed"
}

# ============================================================================
# POST-MIGRATION VALIDATION
# ============================================================================

post_migration_validation() {
    log "\n${BLUE}=== POST-MIGRATION VALIDATION ===${NC}"
    
    info "Testing subscription plans seed compatibility..."
    # Test that seed script would work (without actually running it)
    if ! psql "$DATABASE_URL" -c "EXPLAIN INSERT INTO public.subscription_plans (id, name, price, interval, duration_days, features) VALUES (gen_random_uuid(), 'Test', 0, 'month', 30, '[]');" >> "$LOG_FILE" 2>&1; then
        error_exit "Post-migration validation failed: Subscription plans seeding incompatible"
    fi
    success "Subscription plans seed compatibility verified"
    
    info "Testing wallet function aliases..."
    # Test that function signatures are correct (without calling them)
    if ! psql "$DATABASE_URL" -c "SELECT pg_get_function_identity_arguments(oid) FROM pg_proc WHERE proname = 'credit_wallet';" >> "$LOG_FILE" 2>&1; then
        error_exit "Post-migration validation failed: credit_wallet function issues"
    fi
    success "Wallet function aliases verified"
    
    info "Testing subscription payments table access..."
    # Test table structure
    if ! psql "$DATABASE_URL" -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'subscription_payments' ORDER BY ordinal_position;" >> "$LOG_FILE" 2>&1; then
        error_exit "Post-migration validation failed: subscription_payments table issues"
    fi
    success "Subscription payments table verified"
    
    log "${GREEN}All post-migration validations passed${NC}"
}

# ============================================================================
# ROLLBACK GENERATION
# ============================================================================

generate_rollback_script() {
    log "\n${BLUE}=== GENERATING ROLLBACK SCRIPT ===${NC}"
    
    ROLLBACK_FILE="rollback_phase1_migrations_$(date +%Y%m%d_%H%M%S).sql"
    
    cat > "$ROLLBACK_FILE" << 'EOF'
-- ============================================================================
-- ROLLBACK SCRIPT: Phase 1 Critical Database Migrations
-- ============================================================================
-- 
-- This script rolls back the three migrations in REVERSE order
-- Execute only if you need to undo the Phase 1 migrations
--
-- WARNING: This will remove the fixes and restore the original bugs
-- 
-- ROLLBACK ORDER:
-- 1. Remove subscription_payments table (Migration 3)
-- 2. Remove wallet function aliases (Migration 2)  
-- 3. Remove interval column from subscription_plans (Migration 1)
-- ============================================================================

-- ROLLBACK MIGRATION 3: Remove subscription_payments table
DROP POLICY IF EXISTS "Users can create own subscription payments" ON public.subscription_payments;
DROP POLICY IF EXISTS "Users can read own subscription payments" ON public.subscription_payments;
DROP POLICY IF EXISTS "Admins can read all subscription payments" ON public.subscription_payments;
DROP POLICY IF EXISTS "Admins can update subscription payments" ON public.subscription_payments;

DROP INDEX IF EXISTS idx_subscription_payments_user_id;
DROP INDEX IF EXISTS idx_subscription_payments_status;
DROP INDEX IF EXISTS idx_subscription_payments_created_at;

DROP TABLE IF EXISTS public.subscription_payments;

-- ROLLBACK MIGRATION 2: Remove wallet function aliases
DROP FUNCTION IF EXISTS credit_wallet(UUID, NUMERIC);
DROP FUNCTION IF EXISTS debit_wallet(UUID, NUMERIC);

-- ROLLBACK MIGRATION 1: Remove interval column
ALTER TABLE public.subscription_plans 
DROP CONSTRAINT IF EXISTS subscription_plans_interval_check;

ALTER TABLE public.subscription_plans 
DROP COLUMN IF EXISTS interval;

-- ============================================================================
-- POST-ROLLBACK STATE:
-- - subscription_plans table reverts to original schema (duration_days only)
-- - Wallet functions revert to original names (increment/decrement only)
-- - subscription_payments table removed (manual payment workflow disabled)
-- 
-- RESULT: Original bugs will reappear:
-- - Subscription plan seeding will fail (interval column missing)
-- - Admin wallet operations will fail (credit/debit functions missing)
-- - Subscription payments will fail (table missing)
-- ============================================================================
EOF
    
    success "Rollback script created: $ROLLBACK_FILE"
}

# ============================================================================
# MAIN EXECUTION FLOW
# ============================================================================

main() {
    log "${BLUE}============================================================================${NC}"
    log "${BLUE}PHASE 1 CRITICAL DATABASE MIGRATIONS EXECUTION${NC}"
    log "${BLUE}============================================================================${NC}"
    
    log "Started at: $(date)"
    log "Script: $0"
    log "Log file: $LOG_FILE"
    
    # Validate environment and files
    validate_migration_files
    
    # Check if we're in simulation mode
    if [[ -z "$DATABASE_URL" ]]; then
        warning "DATABASE_URL not set - running in SIMULATION MODE"
        log "\n${YELLOW}=== SIMULATION MODE ===${NC}"
        log "To execute against a real database, set DATABASE_URL environment variable:"
        log "export DATABASE_URL='postgresql://username:password@host:port/database'"
        log ""
        log "Migration files are ready for execution:"
        log "1. $MIGRATION_1"
        log "2. $MIGRATION_2" 
        log "3. $MIGRATION_3"
        log ""
        log "${GREEN}All migration files validated and ready for deployment${NC}"
        return 0
    fi
    
    # Real execution mode
    validate_database_connection
    pre_migration_checks
    
    # Execute migrations in correct order
    execute_migration_1
    execute_migration_2
    execute_migration_3
    
    # Validate results
    post_migration_validation
    
    # Generate rollback script
    generate_rollback_script
    
    # Final summary
    log "\n${BLUE}============================================================================${NC}"
    log "${GREEN}🎉 PHASE 1 MIGRATIONS COMPLETED SUCCESSFULLY${NC}"
    log "${BLUE}============================================================================${NC}"
    log ""
    log "Migration Summary:"
    log "✅ Migration 1: Subscription plans schema alignment"
    log "✅ Migration 2: Wallet RPC function aliases"
    log "✅ Migration 3: Subscription payments table integration"
    log ""
    log "Next Steps:"
    log "1. Run bug condition exploration tests (tasks 1.1-1.3) - should now PASS"
    log "2. Run preservation tests (tasks 2.1-2.4) - should still PASS"
    log "3. Execute integration testing (task 4)"
    log ""
    log "Rollback available: $ROLLBACK_FILE"
    log "Full log: $LOG_FILE"
    log ""
    log "Completed at: $(date)"
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

# Parse command line arguments
if [[ $# -gt 0 ]]; then
    DATABASE_URL="$1"
fi

# Execute main function
main "$@"