#!/bin/bash

# ============================================================================
# Task 2.3: Test Unrelated Table Operations Preservation
# 
# CONTEXT: Phase 1 Critical Database Fixes - Wave 2 (Preservation Testing)
# METHOD: Observation-first methodology on UNFIXED schema
# GOAL: Capture cross-table operation consistency patterns
# 
# EXPECTED OUTCOME: Tests PASS on unfixed schema (other operations unaffected)
# ============================================================================

set -e

echo "🧪 TASK 2.3: UNRELATED TABLE OPERATIONS PRESERVATION TESTING"
echo "============================================================================"
echo "📋 Testing campaigns, applications, users tables + cross-table operations"
echo "🎯 PRESERVATION TESTING - capturing baseline behavior on UNFIXED schema"
echo "🔍 Method: Comprehensive unit tests + property-based testing"
echo "============================================================================"

# Check prerequisites
echo -e "\n📋 CHECKING PREREQUISITES..."

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js to run tests."
    exit 1
fi
echo "✅ Node.js is available"

# Check if we're in the right directory
if [ ! -f "supabase/schema.sql" ]; then
    echo "❌ Not in the correct project directory. Please run from project root."
    exit 1
fi
echo "✅ Project directory confirmed"

# Check for test files
if [ ! -f "test_unrelated_tables_preservation.js" ]; then
    echo "❌ Main preservation test file not found"
    exit 1
fi

if [ ! -f "test_unrelated_tables_pbt.js" ]; then
    echo "❌ Property-based test file not found"
    exit 1
fi
echo "✅ Test files confirmed"

# Install dependencies if needed
echo -e "\n📦 CHECKING DEPENDENCIES..."
if [ ! -d "node_modules" ] || [ ! -f "node_modules/@supabase/supabase-js/package.json" ]; then
    echo "📦 Installing Supabase client..."
    npm install @supabase/supabase-js dotenv 2>/dev/null || {
        echo "⚠️  npm install failed, attempting to run tests without explicit install"
    }
else
    echo "✅ Dependencies available"
fi

# Set up environment if .env doesn't exist
if [ ! -f ".env" ]; then
    echo -e "\n🔧 SETTING UP DEFAULT ENVIRONMENT..."
    cp .env.example .env 2>/dev/null || {
        echo "⚠️  No .env.example found, using default local Supabase settings"
        cat > .env << EOF
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
EOF
    }
    echo "✅ Environment configured"
fi

echo -e "\n🚀 STARTING PRESERVATION TESTING..."
echo "============================================================================"

# Track overall success
OVERALL_SUCCESS=true
TEST_RESULTS=""

# Execute main preservation tests
echo -e "\n📋 PHASE 1: COMPREHENSIVE UNIT PRESERVATION TESTS"
echo "----------------------------------------------------------------------------"

if node test_unrelated_tables_preservation.js; then
    echo -e "\n✅ Unit preservation tests: PASSED"
    TEST_RESULTS="${TEST_RESULTS}✅ Unit Tests: PASSED\n"
else
    echo -e "\n❌ Unit preservation tests: FAILED"
    TEST_RESULTS="${TEST_RESULTS}❌ Unit Tests: FAILED\n"
    OVERALL_SUCCESS=false
fi

# Execute property-based tests
echo -e "\n📋 PHASE 2: PROPERTY-BASED CONSISTENCY TESTS"
echo "----------------------------------------------------------------------------"

if node test_unrelated_tables_pbt.js; then
    echo -e "\n✅ Property-based tests: PASSED"
    TEST_RESULTS="${TEST_RESULTS}✅ Property Tests: PASSED\n"
else
    echo -e "\n❌ Property-based tests: FAILED"
    TEST_RESULTS="${TEST_RESULTS}❌ Property Tests: FAILED\n"
    OVERALL_SUCCESS=false
fi

# Generate final summary
echo -e "\n============================================================================"
echo "📊 TASK 2.3: FINAL PRESERVATION TESTING RESULTS"
echo "============================================================================"

echo -e "\n📈 TEST EXECUTION SUMMARY:"
echo -e "${TEST_RESULTS}"

if [ "$OVERALL_SUCCESS" = true ]; then
    echo -e "\n🎉 TASK 2.3 PRESERVATION TESTING: ✅ SUCCESS"
    echo -e "\n✅ PRESERVATION REQUIREMENTS ESTABLISHED:"
    echo "   ✅ Campaigns table CRUD operations baseline captured"
    echo "   ✅ Applications table CRUD operations baseline captured"  
    echo "   ✅ Users table authentication flows baseline captured"
    echo "   ✅ Cross-table operation consistency patterns documented"
    echo "   ✅ Foreign key relationships integrity validated"
    echo "   ✅ Property-based consistency guarantees established"
    
    echo -e "\n🔒 BASELINE BEHAVIOR DOCUMENTED:"
    echo "   📊 Preservation patterns captured in JSON files"
    echo "   🧪 Comprehensive test suite ready for validation"
    echo "   🎯 Strong preservation guarantees established"
    
    echo -e "\n🚀 NEXT STEPS - TASK 3 IMPLEMENTATION:"
    echo "   1. Implement Phase 1 critical database fixes (Tasks 3.1-3.4)"
    echo "   2. Re-run THESE SAME preservation tests (Task 3.6)"
    echo "   3. Verify ALL tests still PASS (preservation guarantee)"
    echo "   4. Any failing test = REGRESSION requiring immediate fix"
    
    echo -e "\n📋 PRESERVATION VALIDATION COMMAND:"
    echo "   ./run_task_2_3_preservation.sh  # Re-run after fixes"
    echo "   # All results must match current baseline"
    
    echo -e "\n💾 PRESERVATION EVIDENCE SAVED:"
    if [ -f "TASK_2.3_PRESERVATION_PATTERNS.json" ]; then
        echo "   ✅ TASK_2.3_PRESERVATION_PATTERNS.json"
    fi
    if [ -f "TASK_2.3_PROPERTY_RESULTS.json" ]; then
        echo "   ✅ TASK_2.3_PROPERTY_RESULTS.json"
    fi
    
else
    echo -e "\n⚠️  TASK 2.3 PRESERVATION TESTING: ❌ BASELINE ISSUES DETECTED"
    echo -e "\n🚨 CRITICAL FINDINGS:"
    echo "   Some unrelated table operations are already failing"
    echo "   This indicates existing issues beyond the 3 critical fixes"
    echo "   Consider addressing baseline issues before schema changes"
    
    echo -e "\n🔍 RECOMMENDED ACTIONS:"
    echo "   1. Review failed test details in console output above"
    echo "   2. Investigate baseline database health"
    echo "   3. Consider fixing baseline issues first"
    echo "   4. Or proceed with awareness of existing issues"
    
    echo -e "\n⚠️  PROCEED WITH CAUTION:"
    echo "   Baseline failures may complicate regression detection"
    echo "   Ensure schema fixes don't worsen existing issues"
fi

echo -e "\n============================================================================"

# Set exit code based on success
if [ "$OVERALL_SUCCESS" = true ]; then
    echo "🏁 Task 2.3 preservation testing completed successfully"
    exit 0
else
    echo "🏁 Task 2.3 preservation testing completed with baseline issues"
    exit 1
fi