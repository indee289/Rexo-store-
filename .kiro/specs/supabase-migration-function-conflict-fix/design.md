# Supabase Migration Function Conflict Bugfix Design

## Overview

This design addresses the critical Supabase migration deployment failure where Migration 2 (add_wallet_function_aliases.sql) cannot create credit_wallet and debit_wallet functions because they already exist in the database. The solution implements a safe, idempotent migration strategy using conditional function existence checks and DROP IF EXISTS patterns to ensure Phase 1 database fixes can be deployed successfully to production without data loss or service interruption.

## Glossary

- **Bug_Condition (C)**: Migration deployment fails when CREATE OR REPLACE FUNCTION encounters existing functions with incompatible signatures or ownership
- **Property (P)**: Successful migration deployment with function conflict resolution while preserving all existing functionality
- **Preservation**: Existing wallet operations, admin permissions, and data integrity must remain unchanged
- **add_wallet_function_aliases.sql**: Migration 2 file in `/supabase/migrations/` that creates credit_wallet and debit_wallet wrapper functions
- **increment_wallet_balance**: Original SECURITY DEFINER function for atomic wallet deposits with admin role validation
- **decrement_wallet_balance**: Original SECURITY DEFINER function for atomic wallet withdrawals with admin role validation and balance checks
- **Idempotent Migration**: Migration that can be safely executed multiple times without side effects or data corruption

## Bug Details

### Bug Condition

The bug manifests when Migration 2 (add_wallet_function_aliases.sql) executes in Supabase dashboard and encounters existing credit_wallet or debit_wallet functions. PostgreSQL/Supabase prevents CREATE OR REPLACE FUNCTION operations when function signatures, ownership, or security contexts differ from existing functions.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type MigrationExecutionContext
  OUTPUT: boolean
  
  RETURN input.migration_file = 'add_wallet_function_aliases.sql'
         AND (functionExists('credit_wallet') OR functionExists('debit_wallet'))
         AND NOT canReplaceFunction('credit_wallet') 
         AND deployment_fails_with_ownership_error = true
END FUNCTION
```

### Examples

- **Migration 2 with existing credit_wallet**: System throws "yyy13st cannot change function credit_wallet(uuid,numeric) first. HINT: Use DROP FUNCTION credit_wallet(uuid,numeric) first"
- **Migration 2 with existing debit_wallet**: System throws "yyy13st cannot change function debit_wallet(uuid,numeric) first. HINT: Use DROP FUNCTION debit_wallet(uuid,numeric) first"
- **Multiple deployment attempts**: Each retry fails with same ownership error, blocking entire Phase 1 deployment
- **Clean database deployment**: Migration executes successfully when no conflicting functions exist

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Original increment_wallet_balance and decrement_wallet_balance functions must continue working with same admin validation and security restrictions
- Existing wallet balance operations must preserve atomic transaction behavior and negative balance prevention
- Admin deposit/withdrawal approval workflows must continue functioning without modification
- All existing wallet data, user balances, and transaction history must remain intact
- RLS policies and security model for wallet operations must remain unchanged

**Scope:**
All database operations that do NOT involve the credit_wallet and debit_wallet alias functions should be completely unaffected by this fix. This includes:
- Direct calls to increment_wallet_balance and decrement_wallet_balance functions
- All other wallet table operations (SELECT, manual UPDATE via admin dashboard)
- Migration 1 (subscription plans) and Migration 3 (subscription payments) deployment
- Rollback procedures for all Phase 1 migrations

## Hypothesized Root Cause

Based on the bug description and PostgreSQL function behavior, the most likely issues are:

1. **Function Ownership Conflicts**: The existing credit_wallet/debit_wallet functions may have been created by a different user or with different privileges than the migration execution context
   - Supabase migrations run with specific service role privileges
   - Manual function creation may have used different ownership

2. **Signature Incompatibility**: Existing functions may have different parameter types, return types, or security contexts than the migration expects
   - SECURITY DEFINER vs SECURITY INVOKER differences
   - Different parameter names or types

3. **PostgreSQL CREATE OR REPLACE Limitations**: PostgreSQL restricts CREATE OR REPLACE when function characteristics cannot be safely replaced
   - Cannot change function owner via CREATE OR REPLACE
   - Cannot change SECURITY context in some cases

4. **Migration State Inconsistency**: Functions may exist from previous incomplete migration attempts or manual deployments
   - Partial migration rollbacks leaving orphaned functions
   - Development/staging database state differences

## Correctness Properties

Property 1: Bug Condition - Idempotent Migration Execution

_For any_ migration execution where existing credit_wallet or debit_wallet functions are present, the fixed migration SHALL successfully deploy by safely handling function conflicts through conditional DROP and CREATE operations, ensuring all alias functions are created with correct signatures and permissions.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**

Property 2: Preservation - Original Function Behavior

_For any_ wallet operation that does NOT use the new alias functions (direct calls to increment_wallet_balance, decrement_wallet_balance, or other wallet operations), the fixed migration SHALL produce exactly the same behavior as before, preserving all admin validation, security restrictions, atomic transaction behavior, and data integrity.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `/projects/sandbox/Rexo-store-/supabase/migrations/add_wallet_function_aliases.sql`

**Function**: Migration file structure and function creation logic

**Specific Changes**:
1. **Add Idempotent Function Handling**: Replace CREATE OR REPLACE with conditional DROP IF EXISTS followed by CREATE
   - Check function existence before attempting to create
   - Use DROP FUNCTION IF EXISTS to safely remove conflicting functions
   - Ensure clean state before function creation

2. **Add Migration State Validation**: Verify original functions exist before creating aliases
   - Confirm increment_wallet_balance and decrement_wallet_balance are available
   - Fail fast if dependencies are missing
   - Provide clear error messages for troubleshooting

3. **Add Comprehensive Error Handling**: Implement detailed transaction control and validation
   - Use explicit transaction blocks for atomic operations
   - Add validation queries to confirm successful deployment
   - Include rollback-safe error recovery

4. **Add Function Permission Consistency**: Ensure alias functions match original function permissions exactly
   - Grant same permissions as original functions
   - Use same security contexts and ownership patterns
   - Validate permission inheritance from wrapped functions

5. **Add Migration Validation Queries**: Include post-deployment verification steps
   - Verify all expected functions exist with correct signatures
   - Test basic function execution to confirm operational state
   - Validate alias delegation to original functions works correctly

### Technical Implementation Strategy

**Phase 1: Pre-Migration Validation**
```sql
-- Verify original functions exist and are accessible
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'increment_wallet_balance') THEN
    RAISE EXCEPTION 'Migration dependency missing: increment_wallet_balance function not found';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'decrement_wallet_balance') THEN
    RAISE EXCEPTION 'Migration dependency missing: decrement_wallet_balance function not found';
  END IF;
  
  RAISE NOTICE 'Migration validation passed: Original wallet functions available';
END $$;
```

**Phase 2: Safe Function Replacement**
```sql
-- Idempotent function creation with conflict resolution
DROP FUNCTION IF EXISTS credit_wallet(UUID, NUMERIC);
DROP FUNCTION IF EXISTS debit_wallet(UUID, NUMERIC);

-- Create functions with verified clean state
CREATE FUNCTION credit_wallet(...) ...;
CREATE FUNCTION debit_wallet(...) ...;
```

**Phase 3: Post-Migration Validation**
```sql
-- Verify deployment success and function operation
SELECT 
  COUNT(*) as alias_functions_created
FROM pg_proc 
WHERE proname IN ('credit_wallet', 'debit_wallet')
  AND pg_get_function_arguments(oid) = 'p_user_id uuid, p_amount numeric';
-- Expected: 2 functions found
```

## Testing Strategy

### Validation Approach

The testing strategy follows a three-phase approach: first, demonstrate the bug on unfixed migration files, then verify the fix handles conflicts correctly, and finally ensure preservation of all existing functionality.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis by reproducing the exact deployment failure.

**Test Plan**: Create test scenarios that simulate Supabase migration deployment with existing functions. Execute unfixed migration on databases with pre-existing credit_wallet/debit_wallet functions to observe the ownership and signature conflict errors.

**Test Cases**:
1. **Existing Functions Test**: Create credit_wallet and debit_wallet functions manually, then run unfixed migration (will fail with ownership error)
2. **Partial Migration State Test**: Simulate incomplete migration deployment, then retry unfixed migration (will fail with conflict error)
3. **Different Ownership Test**: Create functions with different user ownership, then run unfixed migration (will fail with permission error)
4. **Clean Database Test**: Run unfixed migration on clean database without existing functions (should succeed)

**Expected Counterexamples**:
- CREATE OR REPLACE FUNCTION fails with "cannot change function" errors
- Possible causes: ownership conflicts, signature incompatibility, PostgreSQL security restrictions

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed migration produces successful deployment.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := runFixedMigration(input)
  ASSERT expectedBehavior(result) -- successful deployment with all functions created
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed migration produces the same result as the original migration.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT originalMigration(input) = fixedMigration(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many database state scenarios automatically
- It catches edge cases in function permissions and ownership patterns
- It provides strong guarantees that existing wallet operations are unchanged

**Test Plan**: Document current wallet operation behavior on unfixed systems, then write comprehensive tests to verify this behavior continues after migration fix deployment.

**Test Cases**:
1. **Original Function Preservation**: Verify increment_wallet_balance and decrement_wallet_balance continue working exactly as before
2. **Admin Permission Preservation**: Verify admin role validation continues working for all wallet operations
3. **Balance Validation Preservation**: Verify negative balance prevention continues working correctly
4. **Transaction Atomicity Preservation**: Verify wallet operations maintain atomic behavior under concurrent access

### Unit Tests

- Test migration deployment with various existing function states (none, partial, complete)
- Test function creation with different ownership and permission scenarios
- Test alias function delegation to original functions with all parameter combinations
- Test error handling and rollback scenarios for failed migrations

### Property-Based Tests

- Generate random database states with various function existence patterns and verify migration success
- Generate random wallet operation scenarios and verify preservation of original function behavior
- Test migration execution across many different Supabase project configurations and permission models

### Integration Tests

- Test complete Phase 1 migration sequence (Migration 1 → Migration 2 → Migration 3) with function conflicts
- Test admin dashboard wallet operations after migration deployment
- Test rollback procedures from various migration states
- Test migration re-execution scenarios (idempotent behavior verification)