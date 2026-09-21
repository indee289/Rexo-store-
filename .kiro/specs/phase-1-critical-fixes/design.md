# Phase 1 Critical Database Fixes - Bugfix Design

## Overview

This design document outlines the comprehensive solution for fixing three critical database-level issues in the Rexo Marketplace application. The issues stem from schema mismatches between the database table definitions and the SQL operations that depend on them. The fix involves aligning column names, creating proper function aliases for backward compatibility, and ensuring the subscription_payments table exists with the correct schema. This is a database-first fix that requires careful migration ordering and validation to prevent any data loss or service disruption.

## Glossary

- **Bug_Condition (C)**: The condition that triggers database operation failures - when column names, function names, or table references don't match between schema definitions and dependent SQL operations
- **Property (P)**: The desired behavior when database operations execute successfully - proper schema alignment enabling seamless data operations
- **Preservation**: Existing data integrity and application functionality that must remain unchanged during the migration process
- **subscription_plans**: The table in `supabase/schema.sql` that stores subscription plan information with duration_days column
- **seed_subscription_plans.sql**: The migration script that inserts subscription plan data expecting an `interval` column
- **wallet_balance_rpc.sql**: The RPC functions `increment_wallet_balance` and `decrement_wallet_balance` for atomic wallet operations
- **Admin Provider**: The Flutter service classes that call `credit_wallet` and `debit_wallet` functions for deposit/withdrawal approvals
- **subscription_payments**: The missing table required for the manual subscription payment workflow

## Bug Details

### Bug Condition

The bugs manifest when database operations encounter schema mismatches at three critical points. The `seed_subscription_plans.sql` migration fails because it references a non-existent `interval` column, admin wallet operations fail because they call non-existent `credit_wallet` and `debit_wallet` functions, and subscription payment operations fail because the `subscription_payments` table doesn't exist in the main schema.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type DatabaseOperation
  OUTPUT: boolean
  
  RETURN (input.operation = 'INSERT_SUBSCRIPTION_PLANS' AND input.references_column = 'interval')
         OR (input.operation = 'RPC_CALL' AND input.function_name IN ['credit_wallet', 'debit_wallet'])
         OR (input.operation = 'SUBSCRIPTION_PAYMENT' AND NOT tableExists('subscription_payments'))
END FUNCTION
```

### Examples

- **Subscription Plans Migration**: Running `seed_subscription_plans.sql` crashes with "column interval does not exist" because the schema defines `duration_days` but the insert script expects `interval`
- **Admin Deposit Approval**: Admin approving a deposit fails with "function credit_wallet does not exist" because the actual function is named `increment_wallet_balance`
- **Admin Withdrawal Approval**: Admin approving a withdrawal fails with "function debit_wallet does not exist" because the actual function is named `decrement_wallet_balance`
- **Subscription Payment Submission**: User submitting subscription payment crashes with "table subscription_payments does not exist" because the table hasn't been created in the main schema

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- All existing data in subscription_plans table must remain intact with duration_days values preserved
- Wallet balance operations via the existing increment/decrement functions must continue to work exactly as before
- All other database operations and table schemas must remain completely unaffected
- Row Level Security policies and indexes must remain unchanged
- User authentication and authorization flows must continue working normally

**Scope:**
All database operations that do NOT involve the three specific issues (subscription plan seeding, wallet RPC function calls, subscription payments) should be completely unaffected by this fix. This includes:
- All other table operations (campaigns, applications, users, etc.)
- Authentication and authorization flows
- Storage bucket operations
- Existing RLS policies and triggers

## Hypothesized Root Cause

Based on the bug analysis, the root causes are clear schema misalignment issues:

1. **Column Name Mismatch**: The `subscription_plans` table schema defines a `duration_days INTEGER` column, but the seed script expects an `interval TEXT` column. This suggests the schema was updated at some point but the seed script wasn't synchronized.

2. **Function Name Inconsistency**: The wallet RPC functions are defined as `increment_wallet_balance` and `decrement_wallet_balance` in the database, but the Flutter application code calls `credit_wallet` and `debit_wallet`. This indicates a naming convention mismatch between database and application layers.

3. **Missing Table Implementation**: The `subscription_payments` table exists as a separate migration file (`add_subscription_payments.sql`) but hasn't been included in the main schema, causing application operations to fail when they attempt to use this table.

4. **Migration Orchestration Gap**: The three issues stem from incomplete migration deployment where some components were updated without corresponding updates to their dependencies.

## Correctness Properties

Property 1: Bug Condition - Database Schema Alignment

_For any_ database operation where schema mismatches exist (column names, function names, missing tables), the fixed schema SHALL provide the correct references, enabling successful execution of subscription plan seeding, wallet operations, and subscription payment processing.

**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Preservation - Existing Data and Functionality

_For any_ database operation that does NOT involve the three specific schema mismatches, the fixed schema SHALL produce exactly the same results as the original schema, preserving all existing data, RLS policies, indexes, and application functionality.

**Validates: Requirements 3.1, 3.2, 3.3**

## Fix Implementation

### Changes Required

The fix involves three coordinated database changes that must be applied in the correct order to maintain data integrity:

**Migration 1: Subscription Plans Schema Alignment**

**File**: `supabase/fix_subscription_plans_schema.sql` (new migration file)

**Changes**:
1. **Add Compatibility Column**: Add `interval TEXT` column to existing `subscription_plans` table to support the seed script
2. **Populate Interval Column**: Set interval = 'month' for all existing records to match the seed data expectations
3. **Update Seed Script**: Modify `seed_subscription_plans.sql` to populate both `interval` and `duration_days` columns consistently
4. **Maintain Backward Compatibility**: Keep `duration_days` as the primary column for application use while supporting `interval` for seeding

**Migration 2: Wallet RPC Function Aliases**

**File**: `supabase/add_wallet_function_aliases.sql` (new migration file)

**Changes**:
1. **Create credit_wallet Function**: Create a wrapper function that calls `increment_wallet_balance` with the same parameters
2. **Create debit_wallet Function**: Create a wrapper function that calls `decrement_wallet_balance` with the same parameters
3. **Maintain Security**: Ensure the wrapper functions inherit the same admin-only security restrictions
4. **Grant Permissions**: Apply the same GRANT statements to the new wrapper functions

**Migration 3: Subscription Payments Table Integration**

**File**: `supabase/integrate_subscription_payments.sql` (modified from existing)

**Changes**:
1. **Include in Main Schema**: Move the subscription_payments table definition from the separate migration into the main schema.sql
2. **Ensure Idempotency**: Use `CREATE TABLE IF NOT EXISTS` to prevent conflicts if table already exists
3. **Add Missing Policies**: Ensure all RLS policies from the separate migration are included
4. **Create Indexes**: Include all necessary indexes for optimal performance
5. **Add to Schema Documentation**: Update schema comments to document the subscription payment workflow

### Migration Order and Dependencies

**Critical Execution Sequence:**
1. **First**: Apply subscription plans schema alignment (affects data structure)
2. **Second**: Apply wallet function aliases (affects RPC function availability) 
3. **Third**: Apply subscription payments integration (adds new functionality)
4. **Fourth**: Update seed scripts to use the new schema structure
5. **Finally**: Test all three operations to verify fixes

### Rollback Strategy

Each migration includes corresponding rollback SQL:
- Subscription plans: Remove interval column if added, restore original seed script
- Wallet functions: Drop the alias functions, restore original function names if needed
- Subscription payments: Drop table if it causes issues, restore separate migration approach

## Testing Strategy

### Validation Approach

The testing strategy follows a three-phase approach: first, demonstrate the bugs exist on unfixed schema, then verify each fix resolves its specific issue, and finally confirm no regression has been introduced to existing functionality.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bugs BEFORE implementing the fixes. Confirm the root cause analysis by reproducing each failure scenario.

**Test Plan**: Execute the problematic operations against the current schema to observe and document the exact failure modes. This validates our understanding of the issues before applying fixes.

**Test Cases**:
1. **Subscription Plans Seeding Test**: Run `seed_subscription_plans.sql` against current schema (will fail with "column interval does not exist")
2. **Credit Wallet RPC Test**: Call `credit_wallet` function via Supabase client (will fail with "function credit_wallet does not exist")
3. **Debit Wallet RPC Test**: Call `debit_wallet` function via Supabase client (will fail with "function debit_wallet does not exist")
4. **Subscription Payment Insert Test**: Attempt to insert into `subscription_payments` table (will fail with "table subscription_payments does not exist")

**Expected Counterexamples**:
- Subscription plans migration fails due to column name mismatch
- Wallet operations fail due to function name mismatch
- Subscription payment operations fail due to missing table
- Possible causes: schema drift, incomplete migration deployment, naming convention misalignment

### Fix Checking

**Goal**: Verify that for all inputs where the bug conditions hold, the fixed database schema produces the expected behavior.

**Pseudocode:**
```
FOR ALL operation WHERE isBugCondition(operation) DO
  result := executeOperation_fixed(operation)
  ASSERT expectedBehavior(result)
END FOR
```

**Test Cases**:
1. **Subscription Plans Migration Success**: Verify `seed_subscription_plans.sql` executes without errors and populates both `interval` and `duration_days` columns correctly
2. **Credit Wallet Function Success**: Verify `credit_wallet` RPC calls succeed and properly increment wallet balances
3. **Debit Wallet Function Success**: Verify `debit_wallet` RPC calls succeed and properly decrement wallet balances with balance checks
4. **Subscription Payment Operations Success**: Verify subscription payment records can be inserted, queried, and updated successfully

### Preservation Checking

**Goal**: Verify that for all database operations where the bug conditions do NOT hold, the fixed schema produces the same results as the original schema.

**Pseudocode:**
```
FOR ALL operation WHERE NOT isBugCondition(operation) DO
  ASSERT originalSchema(operation) = fixedSchema(operation)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across different table operations
- It catches edge cases that manual unit tests might miss  
- It provides strong guarantees that existing functionality is unchanged across the entire database schema
- It can verify data integrity across complex multi-table operations

**Test Plan**: Capture baseline behavior of all non-affected operations on the original schema, then verify identical behavior after applying fixes.

**Test Cases**:
1. **Existing Data Preservation**: Verify all existing subscription_plans records maintain their duration_days values and other attributes exactly
2. **Wallet Function Preservation**: Verify `increment_wallet_balance` and `decrement_wallet_balance` continue working identically
3. **Other Table Operations Preservation**: Verify campaigns, applications, users, and all other table operations remain unchanged
4. **RLS Policy Preservation**: Verify all Row Level Security policies continue enforcing the same access controls
5. **Authentication Flow Preservation**: Verify user authentication and authorization continue working normally

### Unit Tests

- Test subscription plans table operations with both `interval` and `duration_days` columns
- Test wallet RPC function calls using both old function names (increment/decrement) and new aliases (credit/debit)
- Test subscription payments table CRUD operations and RLS policy enforcement
- Test edge cases like invalid amounts, unauthorized access, and missing records

### Property-Based Tests

- Generate random subscription plan data and verify both seeding approaches work correctly
- Generate random wallet operation sequences and verify balance consistency between old and new function names
- Generate random subscription payment scenarios and verify table operations handle all valid combinations
- Test cross-table operations to ensure schema changes don't affect foreign key relationships

### Integration Tests

- Test complete subscription purchase flow from payment submission to admin approval
- Test complete wallet management flow from deposit submission to admin approval and balance updates
- Test subscription plan management from seeding to user selection to payment processing
- Test admin dashboard operations accessing all three affected areas simultaneously