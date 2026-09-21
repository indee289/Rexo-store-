# Implementation Plan

## Overview

Implementation tasks for fixing the Supabase migration function conflict where Migration 2 (add_wallet_function_aliases.sql) fails when credit_wallet and debit_wallet functions already exist. The fix implements an idempotent migration strategy using conditional function existence checks and DROP IF EXISTS patterns.

## Task List

- [ ] 1. Write bug condition exploration test
  - **Property 1: Bug Condition** - Migration Deployment Function Conflict
  - **CRITICAL**: This test MUST FAIL on unfixed code - failure confirms the bug exists
  - **DO NOT attempt to fix the test or the code when it fails**
  - **NOTE**: This test encodes the expected behavior - it will validate the fix when it passes after implementation
  - **GOAL**: Surface counterexamples that demonstrate the bug exists
  - **Scoped PBT Approach**: For deterministic bugs, scope the property to the concrete failing case(s) to ensure reproducibility
  - Test that Migration 2 (add_wallet_function_aliases.sql) fails when existing credit_wallet OR debit_wallet functions are present
  - Simulate Supabase migration deployment with pre-existing functions to reproduce ownership/signature conflicts
  - Create test scenarios: existing functions with different ownership, partial migration states, signature conflicts
  - The test assertions should match the Expected Behavior Properties from design: successful migration deployment with idempotent function handling
  - Run test on UNFIXED migration file
  - **EXPECTED OUTCOME**: Test FAILS (this is correct - it proves the bug exists)
  - Document counterexamples found: "CREATE OR REPLACE FUNCTION fails with 'cannot change function' ownership errors"
  - Mark task complete when test is written, run, and failure is documented
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 2. Write preservation property tests (BEFORE implementing fix)
  - **Property 2: Preservation** - Original Function Behavior Preservation
  - **IMPORTANT**: Follow observation-first methodology
  - Observe behavior on UNFIXED migration for non-buggy inputs (clean database without existing functions)
  - Observe that original increment_wallet_balance and decrement_wallet_balance functions continue working unchanged
  - Observe that admin validation, security restrictions, and atomic transaction behavior are preserved
  - Write property-based tests capturing observed behavior patterns from Preservation Requirements
  - Test all wallet operations that do NOT use alias functions (direct calls to increment/decrement functions)
  - Verify admin permission enforcement, balance validation logic, and transaction atomicity remain unchanged
  - Property-based testing generates many test cases for stronger guarantees
  - Run tests on UNFIXED migration
  - **EXPECTED OUTCOME**: Tests PASS (this confirms baseline behavior to preserve)
  - Mark task complete when tests are written, run, and passing on unfixed migration
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 3. Fix for Supabase migration function conflict

  - [ ] 3.1 Implement idempotent migration strategy
    - Replace CREATE OR REPLACE FUNCTION with conditional DROP IF EXISTS followed by CREATE
    - Add pre-migration validation to verify increment_wallet_balance and decrement_wallet_balance functions exist
    - Add explicit transaction blocks for atomic operation handling
    - Add post-migration validation queries to confirm successful deployment
    - Ensure alias functions match original function permissions exactly
    - _Bug_Condition: isBugCondition(input) where input.migration_file = 'add_wallet_function_aliases.sql' AND (functionExists('credit_wallet') OR functionExists('debit_wallet'))_
    - _Expected_Behavior: expectedBehavior(result) - successful migration deployment with all alias functions created correctly_
    - _Preservation: Original increment_wallet_balance and decrement_wallet_balance functions continue working unchanged with same admin validation and security restrictions_
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5_

  - [ ] 3.2 Verify bug condition exploration test now passes
    - **Property 1: Expected Behavior** - Migration Deployment Function Conflict Resolution
    - **IMPORTANT**: Re-run the SAME test from task 1 - do NOT write a new test
    - The test from task 1 encodes the expected behavior
    - When this test passes, it confirms the expected behavior is satisfied
    - Run bug condition exploration test from step 1 on FIXED migration
    - **EXPECTED OUTCOME**: Test PASSES (confirms migration deploys successfully with existing functions)
    - _Requirements: Expected Behavior Properties from design - successful idempotent migration deployment_

  - [ ] 3.3 Verify preservation tests still pass
    - **Property 2: Preservation** - Original Function Behavior Preservation
    - **IMPORTANT**: Re-run the SAME tests from task 2 - do NOT write new tests
    - Run preservation property tests from step 2 on FIXED migration
    - **EXPECTED OUTCOME**: Tests PASS (confirms no regressions to original wallet functions)
    - Confirm all tests still pass after fix (no regressions to increment/decrement functions, admin permissions, balance validation)

- [ ] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Key Implementation Details

### Bug Condition Specification
- **isBugCondition(input)**: Migration 2 executes AND (credit_wallet OR debit_wallet functions exist) AND CREATE OR REPLACE FUNCTION fails with ownership errors

### Expected Behavior Specification
- **expectedBehavior(result)**: Successful migration deployment with idempotent function conflict resolution, all alias functions created with correct signatures and permissions

### Preservation Requirements
- Original increment_wallet_balance and decrement_wallet_balance functions unchanged
- Admin validation and security restrictions preserved
- Atomic transaction behavior and balance validation logic preserved
- All existing wallet data and transaction history intact

### Testing Strategy
- **Exploration Test**: Reproduce migration failures with existing functions to confirm bug exists
- **Preservation Test**: Verify original wallet operations continue working unchanged after fix
- **Property-Based Testing**: Generate many scenarios to ensure comprehensive coverage of function states and permissions