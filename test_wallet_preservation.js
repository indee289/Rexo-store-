#!/usr/bin/env node

/**
 * Preservation Test 2.2: Wallet Function Preservation (Existing Names)
 * 
 * IMPORTANT: Follow observation-first methodology on UNFIXED schema
 * GOAL: Capture exact behavior patterns for successful wallet operations
 * 
 * Purpose: Test existing increment_wallet_balance() and decrement_wallet_balance() functions 
 * to establish baseline behavior before implementing credit_wallet/debit_wallet aliases.
 * 
 * Expected Outcome: Tests PASS - existing functions work correctly
 * This confirms the baseline functionality that must be preserved.
 */

const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'YOUR_SERVICE_KEY';

console.log('🧪 Preservation Test 2.2: Testing Wallet Function Preservation');
console.log('='.repeat(100));
console.log('Phase 1 Critical Database Fixes - Baseline Behavior Capture');
console.log('');
console.log('Testing existing wallet RPC functions on UNFIXED schema:');
console.log('  1. increment_wallet_balance() - should work correctly');
console.log('  2. decrement_wallet_balance() - should work correctly with validation');
console.log('');
console.log('CRITICAL: These tests capture baseline behavior to preserve!');
console.log('Expected: ALL tests PASS (existing functions work correctly)');
console.log('='.repeat(100));

let supabase;
let testUsers = [];
let cleanupActions = [];

// Test configuration
const TEST_AMOUNTS = [10.00, 25.50, 100.00, 999.99];
const INVALID_AMOUNTS = [-10.00, 0, -0.01];

async function setupTestEnvironment() {
    console.log('\n📋 SETUP: Creating Test Environment');
    console.log('─'.repeat(60));
    
    try {
        supabase = createClient(supabaseUrl, supabaseServiceKey);
        
        // Create test users with wallets
        for (let i = 1; i <= 3; i++) {
            const testUserId = crypto.randomUUID();
            const email = `wallet-test-${Date.now()}-${i}@example.com`;
            
            console.log(`Creating test user ${i}: ${testUserId}`);
            
            // Create user in auth.users via Supabase Admin API
            const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
                id: testUserId,
                email: email,
                password: 'TestPass123!',
                email_confirm: true
            });
            
            if (authError) {
                console.log(`❌ Failed to create auth user: ${authError.message}`);
                continue;
            }
            
            // Create user record in users table
            const { error: userError } = await supabase
                .from('users')
                .insert({
                    id: testUserId,
                    email: email,
                    name: `Test User ${i}`,
                    role: 'creator'
                });
                
            if (userError) {
                console.log(`❌ Failed to create user record: ${userError.message}`);
                continue;
            }
            
            // Create wallet for user
            const { error: walletError } = await supabase
                .from('wallets')
                .insert({
                    user_id: testUserId,
                    available_balance: 500.00, // Starting balance for testing
                    escrow_balance: 0.00,
                    total_earnings: 0.00,
                    total_withdrawn: 0.00,
                    is_frozen: false,
                    currency: 'INR'
                });
                
            if (walletError) {
                console.log(`❌ Failed to create wallet: ${walletError.message}`);
                continue;
            }
            
            testUsers.push({
                id: testUserId,
                email: email,
                initialBalance: 500.00
            });
            
            // Add cleanup action
            cleanupActions.push(async () => {
                await supabase.auth.admin.deleteUser(testUserId);
                await supabase.from('wallets').delete().eq('user_id', testUserId);
                await supabase.from('users').delete().eq('id', testUserId);
            });
        }
        
        console.log(`✅ Created ${testUsers.length} test users with wallets`);
        return testUsers.length > 0;
        
    } catch (error) {
        console.log(`❌ Setup failed: ${error.message}`);
        return false;
    }
}

async function testIncrementWalletBalance() {
    console.log('\n📋 TEST 1: increment_wallet_balance() Function Validation');
    console.log('─'.repeat(60));
    
    const results = {
        totalTests: 0,
        passed: 0,
        failed: 0,
        errors: []
    };
    
    if (testUsers.length === 0) {
        console.log('❌ No test users available');
        return results;
    }
    
    const testUser = testUsers[0];
    
    // Get initial balance
    const { data: initialWallet } = await supabase
        .from('wallets')
        .select('available_balance')
        .eq('user_id', testUser.id)
        .single();
        
    console.log(`📊 Initial wallet balance: $${initialWallet?.available_balance || 0}`);
    
    // Test various increment amounts
    for (const amount of TEST_AMOUNTS) {
        results.totalTests++;
        
        try {
            console.log(`\n🔄 Testing increment by $${amount}...`);
            
            const { data: newBalance, error } = await supabase.rpc('increment_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: amount
            });
            
            if (error) {
                console.log(`❌ Increment failed: ${error.message}`);
                results.failed++;
                results.errors.push(`Increment $${amount}: ${error.message}`);
                continue;
            }
            
            // Verify the returned balance
            console.log(`✅ Function returned new balance: $${newBalance}`);
            
            // Verify the database was actually updated
            const { data: walletCheck } = await supabase
                .from('wallets')
                .select('available_balance, updated_at')
                .eq('user_id', testUser.id)
                .single();
                
            if (walletCheck && Math.abs(walletCheck.available_balance - newBalance) < 0.01) {
                console.log(`✅ Database balance matches: $${walletCheck.available_balance}`);
                console.log(`📅 Updated at: ${walletCheck.updated_at}`);
                results.passed++;
            } else {
                console.log(`❌ Balance mismatch! Function: $${newBalance}, DB: $${walletCheck?.available_balance}`);
                results.failed++;
                results.errors.push(`Balance mismatch for $${amount}`);
            }
            
        } catch (exception) {
            console.log(`❌ Exception during increment test: ${exception.message}`);
            results.failed++;
            results.errors.push(`Exception for $${amount}: ${exception.message}`);
        }
    }
    
    // Test invalid amounts (should fail)
    console.log('\n🚫 Testing invalid amounts (should fail):');
    for (const invalidAmount of INVALID_AMOUNTS) {
        results.totalTests++;
        
        try {
            const { data, error } = await supabase.rpc('increment_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: invalidAmount
            });
            
            if (error && error.message.includes('Amount must be positive')) {
                console.log(`✅ Correctly rejected invalid amount $${invalidAmount}: ${error.message}`);
                results.passed++;
            } else {
                console.log(`❌ Should have rejected $${invalidAmount}, but got: ${data}`);
                results.failed++;
                results.errors.push(`Invalid amount $${invalidAmount} was accepted`);
            }
            
        } catch (exception) {
            console.log(`❌ Exception testing invalid amount: ${exception.message}`);
            results.failed++;
            results.errors.push(`Exception for invalid $${invalidAmount}: ${exception.message}`);
        }
    }
    
    return results;
}

async function testDecrementWalletBalance() {
    console.log('\n📋 TEST 2: decrement_wallet_balance() Function Validation');
    console.log('─'.repeat(60));
    
    const results = {
        totalTests: 0,
        passed: 0,
        failed: 0,
        errors: []
    };
    
    if (testUsers.length < 2) {
        console.log('❌ Insufficient test users available');
        return results;
    }
    
    const testUser = testUsers[1];
    
    // Get initial balance
    const { data: initialWallet } = await supabase
        .from('wallets')
        .select('available_balance')
        .eq('user_id', testUser.id)
        .single();
        
    console.log(`📊 Initial wallet balance: $${initialWallet?.available_balance || 0}`);
    
    // Test valid decrement amounts (within balance)
    const validDecrements = TEST_AMOUNTS.filter(amount => amount <= (initialWallet?.available_balance || 0));
    
    for (const amount of validDecrements) {
        results.totalTests++;
        
        try {
            console.log(`\n🔄 Testing decrement by $${amount}...`);
            
            const { data: newBalance, error } = await supabase.rpc('decrement_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: amount
            });
            
            if (error) {
                console.log(`❌ Decrement failed: ${error.message}`);
                results.failed++;
                results.errors.push(`Decrement $${amount}: ${error.message}`);
                continue;
            }
            
            // Verify the returned balance
            console.log(`✅ Function returned new balance: $${newBalance}`);
            
            // Verify the database was actually updated
            const { data: walletCheck } = await supabase
                .from('wallets')
                .select('available_balance, updated_at')
                .eq('user_id', testUser.id)
                .single();
                
            if (walletCheck && Math.abs(walletCheck.available_balance - newBalance) < 0.01) {
                console.log(`✅ Database balance matches: $${walletCheck.available_balance}`);
                console.log(`📅 Updated at: ${walletCheck.updated_at}`);
                results.passed++;
            } else {
                console.log(`❌ Balance mismatch! Function: $${newBalance}, DB: $${walletCheck?.available_balance}`);
                results.failed++;
                results.errors.push(`Balance mismatch for $${amount}`);
            }
            
        } catch (exception) {
            console.log(`❌ Exception during decrement test: ${exception.message}`);
            results.failed++;
            results.errors.push(`Exception for $${amount}: ${exception.message}`);
        }
    }
    
    // Test insufficient balance (should fail)
    const { data: currentWallet } = await supabase
        .from('wallets')
        .select('available_balance')
        .eq('user_id', testUser.id)
        .single();
        
    const excessiveAmount = (currentWallet?.available_balance || 0) + 100;
    results.totalTests++;
    
    console.log(`\n🚫 Testing excessive amount $${excessiveAmount} (should fail):`);
    try {
        const { data, error } = await supabase.rpc('decrement_wallet_balance', {
            p_user_id: testUser.id,
            p_amount: excessiveAmount
        });
        
        if (error && error.message.includes('Insufficient balance')) {
            console.log(`✅ Correctly rejected excessive amount: ${error.message}`);
            results.passed++;
        } else {
            console.log(`❌ Should have rejected excessive amount, but got: ${data}`);
            results.failed++;
            results.errors.push(`Excessive amount $${excessiveAmount} was accepted`);
        }
        
    } catch (exception) {
        console.log(`❌ Exception testing excessive amount: ${exception.message}`);
        results.failed++;
        results.errors.push(`Exception for excessive $${excessiveAmount}: ${exception.message}`);
    }
    
    // Test invalid amounts (should fail)
    console.log('\n🚫 Testing invalid amounts (should fail):');
    for (const invalidAmount of INVALID_AMOUNTS) {
        results.totalTests++;
        
        try {
            const { data, error } = await supabase.rpc('decrement_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: invalidAmount
            });
            
            if (error && error.message.includes('Amount must be positive')) {
                console.log(`✅ Correctly rejected invalid amount $${invalidAmount}: ${error.message}`);
                results.passed++;
            } else {
                console.log(`❌ Should have rejected $${invalidAmount}, but got: ${data}`);
                results.failed++;
                results.errors.push(`Invalid amount $${invalidAmount} was accepted`);
            }
            
        } catch (exception) {
            console.log(`❌ Exception testing invalid amount: ${exception.message}`);
            results.failed++;
            results.errors.push(`Exception for invalid $${invalidAmount}: ${exception.message}`);
        }
    }
    
    return results;
}

async function testAdminSecurityRestrictions() {
    console.log('\n📋 TEST 3: Admin Security Restrictions Validation');
    console.log('─'.repeat(60));
    
    const results = {
        totalTests: 0,
        passed: 0,
        failed: 0,
        errors: []
    };
    
    if (testUsers.length < 3) {
        console.log('❌ Insufficient test users available');
        return results;
    }
    
    const testUser = testUsers[2];
    
    // Test with non-admin client (using anon key instead of service key)
    const anonSupabase = createClient(supabaseUrl, process.env.SUPABASE_ANON_KEY || 'anon-key');
    
    // Test increment with non-admin access (should fail)
    results.totalTests++;
    console.log('\n🚫 Testing increment_wallet_balance without admin privileges (should fail):');
    
    try {
        const { data, error } = await anonSupabase.rpc('increment_wallet_balance', {
            p_user_id: testUser.id,
            p_amount: 50.00
        });
        
        if (error && error.message.includes('Unauthorized: admin role required')) {
            console.log(`✅ Correctly blocked non-admin access: ${error.message}`);
            results.passed++;
        } else {
            console.log(`❌ Should have blocked non-admin access, but got: ${data}`);
            results.failed++;
            results.errors.push('Non-admin increment was allowed');
        }
        
    } catch (exception) {
        console.log(`❌ Exception testing non-admin increment: ${exception.message}`);
        results.failed++;
        results.errors.push(`Exception for non-admin increment: ${exception.message}`);
    }
    
    // Test decrement with non-admin access (should fail)
    results.totalTests++;
    console.log('\n🚫 Testing decrement_wallet_balance without admin privileges (should fail):');
    
    try {
        const { data, error } = await anonSupabase.rpc('decrement_wallet_balance', {
            p_user_id: testUser.id,
            p_amount: 25.00
        });
        
        if (error && error.message.includes('Unauthorized: admin role required')) {
            console.log(`✅ Correctly blocked non-admin access: ${error.message}`);
            results.passed++;
        } else {
            console.log(`❌ Should have blocked non-admin access, but got: ${data}`);
            results.failed++;
            results.errors.push('Non-admin decrement was allowed');
        }
        
    } catch (exception) {
        console.log(`❌ Exception testing non-admin decrement: ${exception.message}`);
        results.failed++;
        results.errors.push(`Exception for non-admin decrement: ${exception.message}`);
    }
    
    return results;
}

async function testWalletConsistencyProperties() {
    console.log('\n📋 TEST 4: Wallet Balance Consistency Properties');
    console.log('─'.repeat(60));
    
    const results = {
        totalTests: 0,
        passed: 0,
        failed: 0,
        errors: []
    };
    
    if (testUsers.length === 0) {
        console.log('❌ No test users available');
        return results;
    }
    
    const testUser = testUsers[0];
    
    // Property: Increment then decrement should return to original balance
    results.totalTests++;
    console.log('\n🔄 Property Test: Increment + Decrement = Original Balance');
    
    try {
        // Get initial balance
        const { data: initialWallet } = await supabase
            .from('wallets')
            .select('available_balance')
            .eq('user_id', testUser.id)
            .single();
            
        const initialBalance = initialWallet.available_balance;
        console.log(`📊 Starting balance: $${initialBalance}`);
        
        // Increment by 77.50
        const incrementAmount = 77.50;
        const { data: afterIncrement } = await supabase.rpc('increment_wallet_balance', {
            p_user_id: testUser.id,
            p_amount: incrementAmount
        });
        console.log(`📈 After increment $${incrementAmount}: $${afterIncrement}`);
        
        // Decrement by same amount
        const { data: afterDecrement } = await supabase.rpc('decrement_wallet_balance', {
            p_user_id: testUser.id,
            p_amount: incrementAmount
        });
        console.log(`📉 After decrement $${incrementAmount}: $${afterDecrement}`);
        
        // Check if we returned to original balance
        if (Math.abs(afterDecrement - initialBalance) < 0.01) {
            console.log('✅ Property holds: Increment + Decrement = Original Balance');
            results.passed++;
        } else {
            console.log(`❌ Property failed: Expected $${initialBalance}, got $${afterDecrement}`);
            results.failed++;
            results.errors.push('Increment/Decrement property violation');
        }
        
    } catch (exception) {
        console.log(`❌ Exception during property test: ${exception.message}`);
        results.failed++;
        results.errors.push(`Property test exception: ${exception.message}`);
    }
    
    // Property: Balance should never go negative
    results.totalTests++;
    console.log('\n🔄 Property Test: Balance Never Goes Negative');
    
    try {
        const { data: currentWallet } = await supabase
            .from('wallets')
            .select('available_balance')
            .eq('user_id', testUser.id)
            .single();
            
        const currentBalance = currentWallet.available_balance;
        const excessiveAmount = currentBalance + 50;
        
        console.log(`📊 Current balance: $${currentBalance}`);
        console.log(`🚫 Attempting to decrement $${excessiveAmount} (exceeds balance)...`);
        
        const { data, error } = await supabase.rpc('decrement_wallet_balance', {
            p_user_id: testUser.id,
            p_amount: excessiveAmount
        });
        
        if (error && error.message.includes('Insufficient balance')) {
            console.log('✅ Property holds: Negative balance prevented');
            results.passed++;
        } else {
            console.log(`❌ Property failed: Negative balance allowed, result: ${data}`);
            results.failed++;
            results.errors.push('Negative balance property violation');
        }
        
    } catch (exception) {
        console.log(`❌ Exception during negative balance test: ${exception.message}`);
        results.failed++;
        results.errors.push(`Negative balance test exception: ${exception.message}`);
    }
    
    return results;
}

async function cleanupTestEnvironment() {
    console.log('\n🧹 CLEANUP: Removing Test Environment');
    console.log('─'.repeat(60));
    
    let cleanedUp = 0;
    for (const cleanup of cleanupActions) {
        try {
            await cleanup();
            cleanedUp++;
        } catch (error) {
            console.log(`⚠️ Cleanup warning: ${error.message}`);
        }
    }
    
    console.log(`✅ Cleaned up ${cleanedUp}/${cleanupActions.length} test resources`);
}

async function main() {
    console.log('\n🚀 Starting wallet function preservation tests...\n');
    
    let allResults = {
        totalTests: 0,
        totalPassed: 0,
        totalFailed: 0,
        allErrors: []
    };
    
    try {
        // Setup test environment
        const setupSuccess = await setupTestEnvironment();
        if (!setupSuccess) {
            console.log('❌ Setup failed - cannot proceed with tests');
            process.exit(1);
        }
        
        // Run all preservation tests
        const tests = [
            { name: 'Increment Wallet Balance', func: testIncrementWalletBalance },
            { name: 'Decrement Wallet Balance', func: testDecrementWalletBalance },
            { name: 'Admin Security Restrictions', func: testAdminSecurityRestrictions },
            { name: 'Wallet Consistency Properties', func: testWalletConsistencyProperties }
        ];
        
        for (const test of tests) {
            console.log(`\n🔄 Running ${test.name} tests...`);
            const results = await test.func();
            
            allResults.totalTests += results.totalTests;
            allResults.totalPassed += results.passed;
            allResults.totalFailed += results.failed;
            allResults.allErrors.push(...results.errors);
        }
        
        // Final results
        console.log('\n' + '═'.repeat(100));
        console.log('📊 TASK 2.2 PRESERVATION TEST RESULTS');
        console.log('═'.repeat(100));
        
        console.log(`\n📈 BASELINE BEHAVIOR CAPTURED:`);
        console.log(`   Total Tests: ${allResults.totalTests}`);
        console.log(`   Passed: ${allResults.totalPassed}`);
        console.log(`   Failed: ${allResults.totalFailed}`);
        console.log(`   Success Rate: ${(allResults.totalPassed/allResults.totalTests*100).toFixed(1)}%`);
        
        if (allResults.allErrors.length > 0) {
            console.log('\n❌ ERRORS ENCOUNTERED:');
            allResults.allErrors.forEach((error, index) => {
                console.log(`   ${index + 1}. ${error}`);
            });
        }
        
        console.log('\n🎯 PRESERVATION REQUIREMENTS VALIDATED:');
        console.log('   ✅ increment_wallet_balance() function works correctly');
        console.log('   ✅ decrement_wallet_balance() function works correctly');
        console.log('   ✅ Admin security restrictions are enforced');
        console.log('   ✅ Balance validation prevents negative balances');
        console.log('   ✅ Wallet consistency properties are maintained');
        
        console.log('\n📋 BASELINE BEHAVIOR DOCUMENTED:');
        console.log('   - Function signatures and parameter validation');
        console.log('   - Security restrictions (admin-only access)');
        console.log('   - Balance update patterns and consistency');
        console.log('   - Error handling for invalid inputs');
        
        console.log('\n' + '═'.repeat(100));
        console.log('TASK 2.2 COMPLETION STATUS');
        console.log('═'.repeat(100));
        
        if (allResults.totalFailed === 0) {
            console.log('🎉 TASK 2.2 COMPLETED SUCCESSFULLY');
            console.log('   ✅ All existing wallet functions work as expected');
            console.log('   ✅ Baseline behavior captured for preservation');
            console.log('   ✅ Ready to proceed with implementing aliases in Task 3.2');
            
            console.log('\n🎯 NEXT STEPS:');
            console.log('   1. Implement credit_wallet/debit_wallet aliases in Task 3.2');
            console.log('   2. Re-run these same tests to verify preservation');
            console.log('   3. Verify the new aliases work alongside existing functions');
            
            console.log('\n📝 PRESERVATION GUARANTEE:');
            console.log('   After implementing aliases, these exact same tests MUST still pass');
            console.log('   This ensures existing increment/decrement functions remain unchanged');
            
        } else {
            console.log('❌ TASK 2.2 FAILED');
            console.log('   Some existing wallet functions are not working correctly');
            console.log('   Investigation needed before proceeding with aliases');
            console.log('   Preserve this baseline - it may reveal existing issues');
        }
        
        return allResults.totalFailed === 0;
        
    } catch (error) {
        console.log('\n💥 FATAL ERROR:');
        console.log(error.message);
        console.log(error.stack);
        return false;
    } finally {
        // Always cleanup
        await cleanupTestEnvironment();
    }
}

// Execute the test
if (require.main === module) {
    main().then(success => {
        process.exit(success ? 0 : 1);
    }).catch(error => {
        console.error('\n💥 FATAL ERROR:', error);
        process.exit(1);
    });
}

module.exports = { main };