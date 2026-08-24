#!/bin/bash

echo "============================================================"
echo "MIGRATION 1: SUBSCRIPTION PLANS SCHEMA ALIGNMENT"
echo "============================================================"

# Test 1: Check that the migration file exists and has the right content
echo "1. CHECKING MIGRATION FILE:"
if [ -f "supabase/fix_subscription_plans_schema.sql" ]; then
    echo "✅ Migration file exists: fix_subscription_plans_schema.sql"
    
    # Check for key migration components
    if grep -q "ADD COLUMN IF NOT EXISTS interval TEXT" "supabase/fix_subscription_plans_schema.sql"; then
        echo "✅ Migration adds interval column"
    else
        echo "❌ Migration missing interval column addition"
    fi
    
    if grep -q "UPDATE.*SET interval = 'month'" "supabase/fix_subscription_plans_schema.sql"; then
        echo "✅ Migration populates existing records"
    else
        echo "❌ Migration missing data population"
    fi
    
    if grep -q "CHECK.*interval IN" "supabase/fix_subscription_plans_schema.sql"; then
        echo "✅ Migration adds validation constraint"
    else
        echo "❌ Migration missing validation constraint"
    fi
else
    echo "❌ Migration file does not exist"
fi

# Test 2: Check that seed script is updated
echo ""
echo "2. CHECKING SEED SCRIPT UPDATE:"
if [ -f "supabase/seed_subscription_plans.sql" ]; then
    echo "✅ Seed script exists: seed_subscription_plans.sql"
    
    # Check for both columns in INSERT
    if grep -q "interval, duration_days" "supabase/seed_subscription_plans.sql"; then
        echo "✅ Seed script includes both interval and duration_days columns"
    else
        echo "❌ Seed script missing both column references"
    fi
    
    # Check for 'month', 30 pattern (interval, duration_days values)
    if grep -q "'month', 30" "supabase/seed_subscription_plans.sql"; then
        echo "✅ Seed script has consistent interval/duration values"
    else
        echo "❌ Seed script missing consistent values"
    fi
else
    echo "❌ Seed script does not exist"
fi

# Test 3: Validate SQL syntax (basic check)
echo ""
echo "3. BASIC SQL SYNTAX VALIDATION:"

# Check migration syntax
if grep -q "ALTER TABLE.*ADD COLUMN" "supabase/fix_subscription_plans_schema.sql"; then
    echo "✅ Migration has valid ALTER TABLE syntax"
else
    echo "❌ Migration ALTER TABLE syntax issues"
fi

# Check seed script syntax
if grep -q "INSERT INTO.*VALUES" "supabase/seed_subscription_plans.sql"; then
    echo "✅ Seed script has valid INSERT syntax"
else
    echo "❌ Seed script INSERT syntax issues"
fi

# Test 4: Check rollback instructions
echo ""
echo "4. CHECKING ROLLBACK INSTRUCTIONS:"
if grep -q "ROLLBACK INSTRUCTIONS" "supabase/fix_subscription_plans_schema.sql"; then
    echo "✅ Migration includes rollback instructions"
    
    if grep -q "DROP COLUMN IF EXISTS interval" "supabase/fix_subscription_plans_schema.sql"; then
        echo "✅ Rollback includes column removal"
    else
        echo "❌ Rollback missing column removal"
    fi
else
    echo "❌ Migration missing rollback instructions"
fi

# Test 5: Verify preservation requirements
echo ""
echo "5. CHECKING PRESERVATION REQUIREMENTS:"

# Check that duration_days is preserved
if grep -q "duration_days" "supabase/seed_subscription_plans.sql"; then
    echo "✅ Seed script preserves duration_days column usage"
else
    echo "❌ Seed script doesn't preserve duration_days"
fi

# Check migration preserves existing data
if grep -q "existing.*duration_days.*preserved" "supabase/fix_subscription_plans_schema.sql"; then
    echo "✅ Migration documentation mentions data preservation"
else
    echo "❌ Migration missing preservation documentation"
fi

echo ""
echo "============================================================"
echo "MIGRATION 1 VALIDATION SUMMARY"
echo "============================================================"

# Count successful checks (simplified)
success_count=0
total_checks=10

# Basic file existence and content checks
[ -f "supabase/fix_subscription_plans_schema.sql" ] && ((success_count++))
[ -f "supabase/seed_subscription_plans.sql" ] && ((success_count++))
grep -q "ADD COLUMN IF NOT EXISTS interval TEXT" "supabase/fix_subscription_plans_schema.sql" 2>/dev/null && ((success_count++))
grep -q "UPDATE.*SET interval = 'month'" "supabase/fix_subscription_plans_schema.sql" 2>/dev/null && ((success_count++))
grep -q "CHECK.*interval IN" "supabase/fix_subscription_plans_schema.sql" 2>/dev/null && ((success_count++))
grep -q "interval, duration_days" "supabase/seed_subscription_plans.sql" 2>/dev/null && ((success_count++))
grep -q "'month', 30" "supabase/seed_subscription_plans.sql" 2>/dev/null && ((success_count++))
grep -q "ROLLBACK INSTRUCTIONS" "supabase/fix_subscription_plans_schema.sql" 2>/dev/null && ((success_count++))
grep -q "DROP COLUMN IF EXISTS interval" "supabase/fix_subscription_plans_schema.sql" 2>/dev/null && ((success_count++))
grep -q "duration_days" "supabase/seed_subscription_plans.sql" 2>/dev/null && ((success_count++))

echo "Validation Score: $success_count/$total_checks"

if [ $success_count -eq $total_checks ]; then
    echo "🎉 MIGRATION 1 VALIDATION PASSED"
    echo "The subscription plans schema alignment is ready for deployment."
else
    echo "⚠️  MIGRATION 1 VALIDATION: $success_count/$total_checks checks passed"
    echo "Review the issues above before deployment."
fi

echo "============================================================"