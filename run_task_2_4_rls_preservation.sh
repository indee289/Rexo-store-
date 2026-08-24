#!/bin/bash

# TASK 2.4: RLS Policy Preservation Testing
# CRITICAL: Tests run on UNFIXED schema to establish security baseline
# EXPECTED OUTCOME: All tests PASS (confirms security boundaries preserved)

echo "🔐 TASK 2.4: RLS Policy Preservation Testing"
echo "=============================================="
echo ""
echo "IMPORTANT: Testing RLS policies on UNFIXED schema"
echo "EXPECTED: All tests PASS (security boundaries unchanged)"
echo ""

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js to run this test."
    exit 1
fi

# Install @supabase/supabase-js if not available
if [ ! -d "node_modules" ] || [ ! -d "node_modules/@supabase" ]; then
    echo "📦 Installing Supabase JavaScript client..."
    npm init -y > /dev/null 2>&1
    npm install @supabase/supabase-js dotenv > /dev/null 2>&1
fi

# Run the RLS policy preservation tests
echo "🔍 Running RLS Policy Preservation Tests..."
echo ""

node test_rls_policy_preservation.js

exit_code=$?

echo ""
echo "=============================================="
if [ $exit_code -eq 0 ]; then
    echo "✅ TASK 2.4 COMPLETED: RLS Policy Preservation"
    echo "All security boundaries verified and preserved"
    echo "Ready to proceed with schema fixes"
else
    echo "❌ TASK 2.4 FAILED: RLS Policy Issues Detected"
    echo "Security concerns found - investigate before proceeding"
fi
echo "=============================================="

exit $exit_code