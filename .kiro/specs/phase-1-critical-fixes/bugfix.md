# Bugfix Requirements Document

## Introduction

The Rexo Marketplace Flutter app contains 3 critical database-level issues that prevent core functionality from working and block production deployment. These schema mismatches, missing tables, and function name mismatches cause crashes when users attempt subscription operations, admin deposit/withdrawal approvals, and subscription payment submissions. All three issues must be resolved to restore basic app functionality.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the seed_subscription_plans.sql migration runs THEN the system crashes with "column interval does not exist" error

1.2 WHEN admin approves a deposit or withdrawal THEN the system fails with "function credit_wallet does not exist" or "function debit_wallet does not exist" error

1.3 WHEN user submits a subscription payment THEN the system crashes with "table subscription_payments does not exist" error

### Expected Behavior (Correct)

2.1 WHEN the seed_subscription_plans.sql migration runs THEN the system SHALL successfully insert subscription plan records without errors

2.2 WHEN admin approves a deposit or withdrawal THEN the system SHALL successfully execute the wallet balance operations using the correct RPC function names

2.3 WHEN user submits a subscription payment THEN the system SHALL successfully insert the payment record into the subscription_payments table

### Unchanged Behavior (Regression Prevention)

3.1 WHEN existing subscription plans are queried THEN the system SHALL CONTINUE TO return plan data with duration_days as integer values

3.2 WHEN non-admin users attempt wallet operations THEN the system SHALL CONTINUE TO reject unauthorized access with proper error messages

3.3 WHEN other database operations are performed THEN the system SHALL CONTINUE TO function normally without affecting unrelated tables or operations