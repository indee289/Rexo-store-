#!/bin/bash

# ==============================================================================
# Task 2.2: Wallet Function Preservation Test Runner
# ==============================================================================
# 
# Purpose: Execute comprehensive preservation tests for existing wallet functions
# Context: Phase 1 Critical Database Fixes - Wave 2 (Preservation Testing)
# 
# IMPORTANT: Follow observation-first methodology on UNFIXED schema
# GOAL: Capture exact behavior patterns for successful wallet operations
# 
# Tests Included:
#   1. Unit Tests: Specific scenarios and edge cases
#   2. Property-Based Tests: Generated comprehensive test scenarios
# 
# Expected Outcome: ALL tests PASS (existing functions work correctly)
# ==============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Test configuration
TEST_TYPE="PRESERVATION"
TASK_ID="2.2"
WAVE="2"

echo -e "${PURPLE}================================================================================${NC}"
echo -e "${PURPLE}TASK 2.2: WALLET FUNCTION PRESERVATION TESTING${NC}"
echo -e "${PURPLE}================================================================================${NC}"
echo -e "${BLUE}Phase 1 Critical Database Fixes - Wave 2 (Preservation Testing)${NC}"
echo ""
echo -e "${YELLOW}🎯 OBJECTIVE:${NC} Capture baseline behavior before implementing fixes"
echo -e "${YELLOW}📊 METHODOLOGY:${NC} Observation-first on UNFIXED schema"
echo -e "${YELLOW}🎯 FUNCTIONS:${NC} increment_wallet_balance() & decrement_wallet_balance()"
echo ""
echo -e "${GREEN}Expected: ALL tests PASS (existing functions work correctly)${NC}"
echo -e "${PURPLE}================================================================================${NC}"

# Check prerequisites
echo -e "\n${BLUE}📋 CHECKING PREREQUISITES${NC}"
echo "────────────────────────────────────────────────────────────────────────────────"

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed or not in PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Node.js available: $(node --version)${NC}"

# Check if npm packages are available
if [ ! -d "node_modules" ] && [ ! -f "package.json" ]; then
    echo -e "${YELLOW}⚠️  No package.json or node_modules found${NC}"
    echo -e "${BLUE}Installing required packages...${NC}"
    npm init -y > /dev/null 2>&1
    npm install @supabase/supabase-js dotenv > /dev/null 2>&1
fi

# Check environment variables
if [ -z "$SUPABASE_URL" ] && [ ! -f ".env" ]; then
    echo -e "${RED}❌ SUPABASE_URL not set and no .env file found${NC}"
    echo -e "${YELLOW}Please set environment variables or create .env file${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Environment configuration available${NC}"

# Check test files exist
UNIT_TEST_FILE="test_wallet_preservation.js"
PBT_TEST_FILE="test_wallet_preservation_pbt.js"

if [ ! -f "$UNIT_TEST_FILE" ]; then
    echo -e "${RED}❌ Unit test file not found: $UNIT_TEST_FILE${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Unit test file found: $UNIT_TEST_FILE${NC}"

if [ ! -f "$PBT_TEST_FILE" ]; then
    echo -e "${RED}❌ Property-based test file not found: $PBT_TEST_FILE${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Property-based test file found: $PBT_TEST_FILE${NC}"

# Test execution tracking
TOTAL_TEST_SUITES=0
PASSED_TEST_SUITES=0
FAILED_TEST_SUITES=0
FAILED_SUITES=()

# Function to run a test suite
run_test_suite() {
    local test_name="$1"
    local test_file="$2"
    local test_description="$3"
    
    TOTAL_TEST_SUITES=$((TOTAL_TEST_SUITES + 1))
    
    echo -e "\n${PURPLE}================================================================================${NC}"
    echo -e "${BLUE}🧪 RUNNING: $test_name${NC}"
    echo -e "${PURPLE}================================================================================${NC}"
    echo -e "${YELLOW}Description:${NC} $test_description"
    echo -e "${YELLOW}Test File:${NC} $test_file"
    echo ""
    
    # Make file executable
    chmod +x "$test_file"
    
    # Run the test and capture output
    local start_time=$(date +%s)
    
    if node "$test_file"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo -e "\n${GREEN}✅ $test_name PASSED${NC} (${duration}s)"
        PASSED_TEST_SUITES=$((PASSED_TEST_SUITES + 1))
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo -e "\n${RED}❌ $test_name FAILED${NC} (${duration}s)"
        FAILED_TEST_SUITES=$((FAILED_TEST_SUITES + 1))
        FAILED_SUITES+=("$test_name")
        return 1
    fi
}

# Execute test suites
echo -e "\n${BLUE}🚀 STARTING TASK 2.2 PRESERVATION TESTS${NC}"
echo "────────────────────────────────────────────────────────────────────────────────"

# Run Unit Tests
run_test_suite \
    "Unit Preservation Tests" \
    "$UNIT_TEST_FILE" \
    "Specific test scenarios for wallet function behavior validation"

# Run Property-Based Tests  
run_test_suite \
    "Property-Based Preservation Tests" \
    "$PBT_TEST_FILE" \
    "Generated comprehensive scenarios for wallet function properties"

# Final results and analysis
echo -e "\n${PURPLE}================================================================================${NC}"
echo -e "${PURPLE}📊 TASK 2.2 FINAL RESULTS & ANALYSIS${NC}"
echo -e "${PURPLE}================================================================================${NC}"

echo -e "\n${BLUE}📈 TEST EXECUTION SUMMARY:${NC}"
echo "────────────────────────────────────────────────────────────────────────────────"
echo -e "Total Test Suites: ${TOTAL_TEST_SUITES}"
echo -e "${GREEN}Passed: ${PASSED_TEST_SUITES}${NC}"
echo -e "${RED}Failed: ${FAILED_TEST_SUITES}${NC}"

if [ ${#FAILED_SUITES[@]} -gt 0 ]; then
    echo -e "\n${RED}Failed Test Suites:${NC}"
    for suite in "${FAILED_SUITES[@]}"; do
        echo -e "  ❌ $suite"
    done
fi

echo -e "\n${BLUE}🎯 PRESERVATION REQUIREMENTS ANALYSIS:${NC}"
echo "────────────────────────────────────────────────────────────────────────────────"

if [ $FAILED_TEST_SUITES -eq 0 ]; then
    echo -e "${GREEN}✅ ALL PRESERVATION TESTS PASSED${NC}"
    echo ""
    echo -e "${GREEN}🛡️  BASELINE BEHAVIOR SUCCESSFULLY CAPTURED:${NC}"
    echo -e "   📊 increment_wallet_balance() function works correctly"
    echo -e "   📉 decrement_wallet_balance() function works correctly  "
    echo -e "   🔒 Admin security restrictions are properly enforced"
    echo -e "   ⚖️  Balance validation prevents negative balances"
    echo -e "   📈 Wallet consistency properties are maintained"
    echo ""
    echo -e "${BLUE}📋 PRESERVATION GUARANTEE ESTABLISHED:${NC}"
    echo -e "   ✅ These exact behaviors MUST be preserved after alias implementation"
    echo -e "   ✅ Both unit tests and property-based tests provide comprehensive coverage"
    echo -e "   ✅ Strong baseline documented for regression prevention"
    echo ""
    echo -e "${YELLOW}🎯 NEXT STEPS:${NC}"
    echo -e "   1. Proceed to Task 3.2: Create wallet RPC function aliases"
    echo -e "   2. Re-run these same tests after alias implementation"  
    echo -e "   3. Verify aliases work alongside existing functions"
    echo ""
    echo -e "${GREEN}🎉 TASK 2.2 COMPLETED SUCCESSFULLY${NC}"
    
else
    echo -e "${RED}❌ PRESERVATION TESTS FAILED${NC}"
    echo ""
    echo -e "${RED}🚨 CRITICAL ISSUES DETECTED:${NC}"
    echo -e "   ❌ Some existing wallet functions are not working correctly"
    echo -e "   ❌ Baseline behavior cannot be guaranteed for preservation"
    echo -e "   ❌ Investigation needed before proceeding with aliases"
    echo ""
    echo -e "${YELLOW}⚠️  RECOMMENDED ACTIONS:${NC}"
    echo -e "   1. Review failed test outputs for root cause analysis"
    echo -e "   2. Check database connectivity and permissions"
    echo -e "   3. Verify Supabase configuration and RLS policies"
    echo -e "   4. Fix existing issues before implementing aliases"
    echo ""
    echo -e "${RED}❌ TASK 2.2 FAILED - DO NOT PROCEED TO ALIAS IMPLEMENTATION${NC}"
fi

echo -e "\n${BLUE}📝 PRESERVATION METHODOLOGY NOTES:${NC}"
echo "────────────────────────────────────────────────────────────────────────────────"
echo -e "✅ Observation-first approach: tested unfixed schema behavior"
echo -e "✅ Comprehensive coverage: both unit tests and property-based tests"  
echo -e "✅ Baseline documentation: captured exact function behavior patterns"
echo -e "✅ Regression prevention: established test suite for future validation"

echo -e "\n${PURPLE}================================================================================${NC}"
echo -e "${PURPLE}TASK 2.2 EXECUTION COMPLETED${NC}"
echo -e "${PURPLE}================================================================================${NC}"

# Exit with appropriate code
if [ $FAILED_TEST_SUITES -eq 0 ]; then
    echo -e "\n${GREEN}✅ All preservation tests passed - ready for alias implementation${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Preservation tests failed - fix existing issues before proceeding${NC}"
    exit 1
fi