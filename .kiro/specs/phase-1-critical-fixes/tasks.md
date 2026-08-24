# Implementation Plan - Phase 1 Critical Database Fixes

## Overview
This task list implements the exploratory bugfix workflow for resolving three critical database schema mismatches in the Rexo Marketplace. The tasks follow the bug condition methodology: explore the bugs first, write preservation tests, then implement fixes with proper validation.

## Task Dependency Graph

```
Task Dependencies:
1 (Bug Exploration) → 3 (Implementation) → 4 (Integration Testing)
2 (Preservation) → 3 (Implementation) → 4 (Integration Testing)
3 (Implementation) → 5 (Rollback & Docs) → 6 (Checkpoint)
4 (Integration Testing) → 6 (Checkpoint)

Critical Path: 1 → 2 → 3.1-3.4 → 3.5-3.6 → 4 → 5 → 6

Sequential Dependencies Within Task 3:
3.1 (Subscription Schema) → 3.4 (Execute Migrations)
3.2 (Wallet Aliases) → 3.4 (Execute Migrations)  
3.3 (Payments Table) → 3.4 (Execute Migrations)
3.4 (Execute Migrations) → 3.5 (Verify Bug Fixes)
3.5 (Verify Bug Fixes) → 3.6 (Verify Preservation)

Parallel Execution Opportunities:
- Tasks 1.1, 1.2, 1.3 can run in parallel (all bug exploration)
- Tasks 2.1, 2.2, 2.3, 2.4 can run in parallel (all preservation)
- Tasks 3.1, 3.2, 3.3 can be prepared in parallel (migration creation)
- Tasks 4.1, 4.2, 4.3, 4.4 can run in parallel (integration testing)
```

## Tasks

- [ ] 1. Write bug condition exploration tests
  - **Property 1: Bug Condition** - Schema Mismatch Validation
  - **CRITICAL**: These tests MUST FAIL on unfixed schema - failure confirms the bugs exist
  - **DO NOT attempt to fix the tests or the schema when they fail**
  - **NOTE**: These tests encode the expected behavior - they will validate the fixes when they pass after implementation
  - **GOAL**: Surface counterexamples that demonstrate the three database bugs exist
  - **Scoped PBT Approach**: For deterministic schema issues, scope the property to the concrete failing cases to ensure reproducibility

  - [ ] 1.1 Test subscription plans migration failure
    - Create test script that executes `seed_subscription_plans.sql` against current schema
    - Verify it crashes with "column interval does not exist" error
    - Document the exact error message and stack trace
    - **EXPECTED OUTCOME**: Test FAILS (confirms subscription plans schema mismatch)

  - [ ] 1.2 Test wallet RPC function failures
    - Create test script that calls `credit_wallet` function via Supabase client
    - Create test script that calls `debit_wallet` function via Supabase client
    - Verify both crash with "function does not exist" errors
    - Document the exact error messages for each function
    - **EXPECTED OUTCOME**: Tests FAIL (confirms wallet function name mismatches)

  - [ ] 1.3 Test subscription payment table failure
    - Create test script that attempts INSERT into `subscription_payments` table
    - Verify it crashes with "table subscription_payments does not exist" error
    - Document the exact error message and operation details
    - **EXPECTED OUTCOME**: Test FAILS (confirms missing table issue)

  - Mark task complete when all three test failures are documented and understood
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 2. Write preservation property tests (BEFORE implementing fixes)
  - **Property 2: Preservation** - Existing Functionality Protection
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED schema for non-buggy operations
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED schema
  - **EXPECTED OUTCOME**: Tests PASS (confirms baseline behavior to preserve)

  - [ ] 2.1 Test existing subscription plans data preservation
    - Query all existing subscription_plans records and capture duration_days values
    - Create property-based test verifying duration_days integrity is maintained
    - Test subscription plan queries return consistent data structure
    - **EXPECTED OUTCOME**: Tests PASS on unfixed schema (baseline behavior)

  - [ ] 2.2 Test wallet function preservation (existing names)
    - Test `increment_wallet_balance` function calls with various amounts
    - Test `decrement_wallet_balance` function calls with balance validation
    - Capture exact behavior patterns for successful wallet operations
    - Create property-based tests for wallet balance consistency
    - **EXPECTED OUTCOME**: Tests PASS on unfixed schema (existing functions work)

  - [ ] 2.3 Test unrelated table operations preservation
    - Test campaigns table CRUD operations
    - Test applications table CRUD operations  
    - Test users table authentication flows
    - Create property-based tests for cross-table operation consistency
    - **EXPECTED OUTCOME**: Tests PASS on unfixed schema (other operations unaffected)

  - [ ] 2.4 Test RLS policy preservation
    - Test Row Level Security enforcement for all affected tables
    - Verify unauthorized access rejection patterns
    - Create tests for admin vs user permission boundaries
    - **EXPECTED OUTCOME**: Tests PASS on unfixed schema (security unchanged)

  - Mark task complete when preservation tests are written, run, and passing on unfixed schema
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] 3. Fix Phase 1 Critical Database Issues

  - [ ] 3.1 Create Migration 1: Subscription Plans Schema Alignment
    - Create `supabase/migrations/fix_subscription_plans_schema.sql`
    - Add `interval TEXT` column to existing subscription_plans table
    - Populate interval = 'month' for all existing records
    - Update seed script to populate both interval and duration_days consistently
    - Include rollback instructions as comments
    - **Migration Order**: FIRST (affects data structure)
    - _Bug_Condition: isBugCondition(input) where input.operation = 'INSERT_SUBSCRIPTION_PLANS' AND input.references_column = 'interval'_
    - _Expected_Behavior: expectedBehavior(result) - successful seed script execution without column errors_
    - _Preservation: Existing duration_days data and subscription plan functionality from design_
    - _Requirements: 2.1, 3.1_

  - [ ] 3.2 Create Migration 2: Wallet RPC Function Aliases
    - Create `supabase/migrations/add_wallet_function_aliases.sql`
    - Create `credit_wallet` wrapper function calling `increment_wallet_balance`
    - Create `debit_wallet` wrapper function calling `decrement_wallet_balance`
    - Apply same admin-only security restrictions to wrapper functions
    - Include proper GRANT statements for function permissions
    - Include rollback instructions as comments
    - **Migration Order**: SECOND (affects RPC function availability)
    - _Bug_Condition: isBugCondition(input) where input.operation = 'RPC_CALL' AND input.function_name IN ['credit_wallet', 'debit_wallet']_
    - _Expected_Behavior: expectedBehavior(result) - successful wallet operations via alias functions_
    - _Preservation: Existing increment/decrement wallet functions continue working unchanged_
    - _Requirements: 2.2, 3.2_

  - [ ] 3.3 Create Migration 3: Subscription Payments Table Integration
    - Create `supabase/migrations/integrate_subscription_payments.sql`
    - Use CREATE TABLE IF NOT EXISTS for idempotency
    - Include complete table schema from add_subscription_payments.sql
    - Add all RLS policies and indexes from separate migration
    - Update schema documentation with subscription payment workflow
    - Include rollback instructions as comments
    - **Migration Order**: THIRD (adds new functionality)
    - _Bug_Condition: isBugCondition(input) where input.operation = 'SUBSCRIPTION_PAYMENT' AND NOT tableExists('subscription_payments')_
    - _Expected_Behavior: expectedBehavior(result) - successful subscription payment operations_
    - _Preservation: No impact on existing tables or operations_
    - _Requirements: 2.3_

  - [ ] 3.4 Execute migrations in correct order
    - Apply Migration 1: Subscription Plans Schema Alignment
    - Apply Migration 2: Wallet RPC Function Aliases  
    - Apply Migration 3: Subscription Payments Table Integration
    - Verify each migration completes without errors
    - Document any warnings or notices from migration execution
    - _Requirements: All requirements 2.1, 2.2, 2.3_

  - [ ] 3.5 Verify bug condition exploration tests now pass
    - **Property 1: Expected Behavior** - Schema Alignment Validation
    - **IMPORTANT**: Re-run the SAME tests from task 1 - do NOT write new tests
    - The tests from task 1 encode the expected behavior
    - When these tests pass, it confirms the expected behavior is satisfied

    - [ ] 3.5.1 Re-run subscription plans migration test
      - Execute the seed_subscription_plans.sql test from task 1.1
      - **EXPECTED OUTCOME**: Test PASSES (confirms schema alignment fix)
      - Verify both interval and duration_days columns are populated correctly

    - [ ] 3.5.2 Re-run wallet RPC function tests  
      - Execute the credit_wallet and debit_wallet tests from task 1.2
      - **EXPECTED OUTCOME**: Tests PASS (confirms function alias fix)
      - Verify wallet balances are updated correctly via new alias functions

    - [ ] 3.5.3 Re-run subscription payment table test
      - Execute the subscription_payments INSERT test from task 1.3  
      - **EXPECTED OUTCOME**: Test PASSES (confirms table integration fix)
      - Verify subscription payment records are created successfully

    - _Requirements: Expected Behavior Properties from design - 2.1, 2.2, 2.3_

  - [ ] 3.6 Verify preservation tests still pass
    - **Property 2: Preservation** - Existing Functionality Protection
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run all preservation property tests from step 2
    - **EXPECTED OUTCOME**: All tests PASS (confirms no regressions)

    - [ ] 3.6.1 Re-run subscription plans data preservation tests
      - Execute preservation tests from task 2.1
      - **EXPECTED OUTCOME**: Tests PASS (duration_days data intact)

    - [ ] 3.6.2 Re-run wallet function preservation tests
      - Execute preservation tests from task 2.2  
      - **EXPECTED OUTCOME**: Tests PASS (original functions still work)

    - [ ] 3.6.3 Re-run unrelated operations preservation tests
      - Execute preservation tests from task 2.3
      - **EXPECTED OUTCOME**: Tests PASS (other tables unaffected)

    - [ ] 3.6.4 Re-run RLS policy preservation tests
      - Execute preservation tests from task 2.4
      - **EXPECTED OUTCOME**: Tests PASS (security policies unchanged)

- [ ] 4. Integration Testing and Validation

  - [ ] 4.1 Test complete subscription workflow
    - Test subscription plan seeding with new schema structure
    - Test subscription payment submission end-to-end
    - Test subscription management operations
    - Verify no errors occur in the complete flow
    - _Requirements: 2.1, 2.3_

  - [ ] 4.2 Test complete wallet management workflow  
    - Test deposit submission and admin approval via credit_wallet
    - Test withdrawal submission and admin approval via debit_wallet
    - Test balance consistency between old and new function names
    - Verify all wallet operations maintain proper security
    - _Requirements: 2.2, 3.2_

  - [ ] 4.3 Test admin dashboard operations
    - Test admin access to subscription plans management
    - Test admin wallet operation approvals
    - Test admin subscription payment oversight
    - Verify all three fixed areas work together seamlessly
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ] 4.4 Performance and security validation
    - Verify query performance hasn't degraded with schema changes
    - Test RLS policy enforcement across all affected operations
    - Validate database connection pooling still works properly
    - Check for any memory or connection leaks in new operations
    - _Requirements: 3.1, 3.2, 3.3_

- [ ] 5. Rollback Procedures and Documentation

  - [ ] 5.1 Create rollback scripts
    - Create rollback script for subscription plans schema (remove interval column)
    - Create rollback script for wallet function aliases (drop wrapper functions)
    - Create rollback script for subscription payments integration (revert to separate migration)
    - Test rollback scripts on a copy of the migrated database
    - Document rollback execution order and dependencies
    - _Requirements: All preservation requirements_

  - [ ] 5.2 Update documentation
    - Update database schema documentation with new column and functions
    - Update API documentation for wallet function aliases
    - Update developer setup instructions with new migration requirements
    - Document the three critical fixes and their resolution approach
    - _Requirements: All requirements_

  - [ ] 5.3 Create monitoring and alerting
    - Set up monitoring for subscription plan seeding operations
    - Set up alerting for wallet function call failures
    - Set up monitoring for subscription payment table operations
    - Create dashboards showing the health of all three fixed areas
    - _Requirements: 2.1, 2.2, 2.3_

- [ ] 6. Checkpoint - Ensure all tests pass and system is stable
  - Verify all exploration tests now pass (confirming fixes work)
  - Verify all preservation tests still pass (confirming no regressions)  
  - Confirm database is in a consistent, production-ready state
  - Validate that all three critical issues are resolved
  - Ask user if any questions arise about the implementation or testing

## Migration Execution Summary

**Critical Order Requirements:**
1. **First**: Subscription Plans Schema Alignment (affects existing data structure)
2. **Second**: Wallet RPC Function Aliases (adds new function names) 
3. **Third**: Subscription Payments Table Integration (adds new table)

**Rollback Strategy:**
- Each migration includes rollback instructions
- Rollbacks must be executed in reverse order
- Test rollback procedures before production deployment

**Validation Checkpoints:**
- After each migration: verify no errors in execution
- After all migrations: run complete test suite
- Before production: execute full integration test scenarios

## Notes

### Bug Condition Methodology Application
This implementation follows the systematic bug condition methodology:
- **C(X)**: Bug conditions identify inputs that trigger schema mismatches
- **P(result)**: Properties define expected behavior for successful operations  
- **¬C(X)**: Non-buggy operations that must be preserved during fixes
- **F → F'**: Transform unfixed schema to fixed schema while maintaining integrity

### Critical Implementation Constraints
1. **Migration Order**: Must execute in sequence (1→2→3) due to dependencies
2. **Test-First Approach**: All bugs must be demonstrated before fixing
3. **Preservation Priority**: Existing functionality cannot be broken
4. **Rollback Readiness**: Every migration must be reversible

### Property-Based Testing Strategy
- **Exploration Tests**: Demonstrate concrete bug conditions with deterministic inputs
- **Preservation Tests**: Use property-based generation for comprehensive coverage
- **Integration Tests**: Validate complete workflows across all three fixes

### Production Deployment Considerations
- Execute migrations during maintenance window
- Monitor database performance after each migration
- Validate RLS policies remain effective post-migration
- Test rollback procedures on staging environment first

### Risk Mitigation
- **Schema Changes**: Tested against production data copies
- **Function Aliases**: Maintain backward compatibility with existing names
- **New Tables**: Use IF NOT EXISTS for idempotent deployment
- **Security**: Preserve all existing RLS policies and permissions