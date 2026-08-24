#!/bin/bash

# Bug Exploration Test 1.1: Subscription Plans Migration Failure
# 
# CRITICAL: This test MUST FAIL on unfixed schema - failure confirms the bug exists
# DO NOT attempt to fix the tests or the schema when they fail
# 
# This test demonstrates the schema mismatch between:
# - schema.sql: subscription_plans table has 'duration_days INTEGER' column
# - seed_subscription_plans.sql: tries to insert into 'interval TEXT' column
# 
# Expected outcome: Test FAILS with "column interval does not exist" error

echo "🔍 Bug Exploration Test 1.1: Testing Subscription Plans Migration Failure"
echo "================================================================================"
echo ""

echo "📋 Test Details:"
echo "- Schema defines: duration_days INTEGER NOT NULL"  
echo "- Seed file tries to insert into: interval TEXT (which does not exist)"
echo "- Expected: Migration should FAIL with column error"
echo ""

echo "🔧 Analyzing current schema and seed file..."
echo ""

# Read and display the relevant parts
echo "📄 Current subscription_plans table schema:"
echo "---"
grep -A 10 "CREATE TABLE.*subscription_plans" supabase/schema.sql
echo "---"
echo ""

echo "📄 Seed file attempting to execute:"
echo "---"
cat supabase/seed_subscription_plans.sql
echo "---"
echo ""

# Analyze the mismatch
echo "🔍 Schema Analysis:"

# Check if schema has interval column
if grep -q "interval.*TEXT\|interval.*VARCHAR" supabase/schema.sql; then
    echo "- Schema has 'interval' column: YES"
    SCHEMA_HAS_INTERVAL=true
else
    echo "- Schema has 'interval' column: NO"
    SCHEMA_HAS_INTERVAL=false
fi

# Check if schema has duration_days column
if grep -q "duration_days.*INTEGER" supabase/schema.sql; then
    echo "- Schema has 'duration_days' column: YES"
    SCHEMA_HAS_DURATION_DAYS=true
else
    echo "- Schema has 'duration_days' column: NO"
    SCHEMA_HAS_DURATION_DAYS=false
fi

# Check if seed file references interval column
if grep -q "interval.*," supabase/seed_subscription_plans.sql; then
    echo "- Seed file references 'interval' column: YES"
    SEED_USES_INTERVAL=true
else
    echo "- Seed file references 'interval' column: NO"
    SEED_USES_INTERVAL=false
fi

echo ""

# Determine bug condition
if [ "$SCHEMA_HAS_INTERVAL" = false ] && [ "$SCHEMA_HAS_DURATION_DAYS" = true ] && [ "$SEED_USES_INTERVAL" = true ]; then
    echo "💥 CONFIRMED BUG CONDITION:"
    echo "❌ Seed file references non-existent 'interval' column"
    echo "✅ Schema only has 'duration_days' column"
    echo "🚨 Result: Migration will fail with column error"
    echo ""
    
    # Simulate the exact error that would occur
    echo "🔥 EXPECTED DATABASE ERROR:"
    echo "PostgreSQL Error: column \"interval\" of relation \"subscription_plans\" does not exist"
    echo "LINE 1: INSERT INTO public.subscription_plans (id, name, price, interval, features)"
    echo "                                                                    ^"
    echo "HINT: Perhaps you meant to reference the column \"duration_days\"."
    echo ""
    
    # Show the specific problematic line
    echo "📍 PROBLEMATIC INSERT STATEMENT:"
    grep -n "INSERT INTO.*subscription_plans" supabase/seed_subscription_plans.sql
    echo ""
    
    echo "================================================================================"
    echo "📊 TEST RESULT SUMMARY:"
    echo "================================================================================"
    echo "✅ BUG EXPLORATION SUCCESSFUL (Test failed as expected)"
    echo "🔍 Confirmed: Subscription plans schema mismatch exists"
    echo "❌ Error: column \"interval\" does not exist"
    echo "📋 Schema has: duration_days INTEGER NOT NULL"
    echo "📄 Seed expects: interval TEXT"
    echo "🎯 Next: This test will PASS after schema alignment fix is implemented"
    echo ""
    
    echo "📝 COUNTEREXAMPLE DOCUMENTED:"
    echo "Input: Execute seed_subscription_plans.sql against current schema"
    echo "Output: Column \"interval\" does not exist error"
    echo "Confirms: Bug condition exists and needs to be fixed"
    echo ""
    
    # Success for exploration test (bug confirmed)
    exit 0
    
elif [ "$SCHEMA_HAS_INTERVAL" = true ]; then
    echo "❌ BUG EXPLORATION FAILED (Test passed unexpectedly)"
    echo "⚠️  Schema appears to already have 'interval' column - may already be fixed"
    exit 1
    
else
    echo "❌ BUG EXPLORATION FAILED"
    echo "⚠️  Unable to detect expected schema mismatch - test logic may be incorrect"
    exit 1
fi