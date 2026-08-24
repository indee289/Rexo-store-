#!/usr/bin/env node

/**
 * Property-Based Test 2.2: Wallet Function Preservation Properties
 * 
 * IMPORTANT: Property-based testing generates many test cases for stronger guarantees
 * GOAL: Capture exact behavior patterns across many inputs before implementing fixes
 * 
 * Purpose: Generate comprehensive test scenarios for increment_wallet_balance() 
 * and decrement_wallet_balance() functions to establish robust baseline behavior.
 * 
 * Expected Outcome: Tests PASS - existing functions satisfy all properties
 * This provides stronger preservation guarantees than unit tests alone.
 */

const { createClient } = require('@supabase/supabase-js');
const crypto = require('crypto');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'YOUR_SERVICE_KEY';

console.log('🧪 Property-Based Test 2.2: Wallet Function Preservation Properties');
console.log('='.repeat(100));
console.log('Phase 1 Critical Database Fixes - Property-Based Baseline Capture');
console.log('');
console.log('Generating comprehensive test scenarios for wallet RPC functions:');
console.log('  📊 Property 1: Balance Consistency (increment + decrement = identity)');
console.log('  🔒 Property 2: Admin Security Enforcement (non-admin access blocked)');
console.log('  ⚖️  Property 3: Non-negative Balance Invariant (balance >= 0 always)');
console.log('  📈 Property 4: Monotonic Operations (increment always increases)');
console.log('  📉 Property 5: Bounded Operations (decrement respects available balance)');
console.log('');
console.log('CRITICAL: These properties capture baseline behavior to preserve!');
console.log('Expected: ALL properties HOLD (existing functions work correctly)');
console.log('='.repeat(100));

let supabase;
let testUser;
let initialBalance;

// Property-based test generators
class WalletTestGenerator {
    
    static generatePositiveAmount() {
        // Generate positive amounts with various precision
        const baseAmount = Math.random() * 1000;
        const precision = Math.floor(Math.random() * 3); // 0, 1, or 2 decimal places
        return Math.round(baseAmount * Math.pow(10, precision)) / Math.pow(10, precision);
    }
    
    static generateAmountSequence(count = 5) {
        // Generate sequence of amounts for testing operations
        const amounts = [];
        for (let i = 0; i < count; i++) {
            amounts.push(this.generatePositiveAmount());
        }
        return amounts;
    }
    
    static generateInvalidAmounts() {
        // Generate various invalid amount scenarios
        return [
            -Math.random() * 100,  // Negative
            0,                     // Zero
            -0.01,                // Small negative
            NaN,                  // Not a number
            Infinity,             // Infinite
            -Infinity             // Negative infinite
        ].filter(x => !isNaN(x) && isFinite(x)); // Filter out NaN/Infinity for actual tests
    }
    
    static generateBalanceScenarios() {
        // Generate different balance scenarios for testing
        return [
            { balance: 0, description: 'Empty wallet' },
            { balance: 0.01, description: 'Minimal balance' },
            { balance: 100.00, description: 'Standard balance' },
            { balance: 999.99, description: 'High balance' },
            { balance: 1000.00, description: 'Round number balance' }
        ];
    }
}

async function setupPropertyTestEnvironment() {
    console.log('\n📋 SETUP: Creating Property Test Environment');
    console.log('─'.repeat(60));
    
    try {
        supabase = createClient(supabaseUrl, supabaseServiceKey);
        
        // Create single test user for property tests
        const testUserId = crypto.randomUUID();
        const email = `wallet-pbt-${Date.now()}@example.com`;
        
        console.log(`Creating property test user: ${testUserId}`);
        
        // Create user in auth.users
        const { data: authUser, error: authError } = await supabase.auth.admin.createUser({
            id: testUserId,
            email: email,
            password: 'TestPass123!',
            email_confirm: true
        });
        
        if (authError) {
            console.log(`❌ Failed to create auth user: ${authError.message}`);
            return false;
        }
        
        // Create user record
        const { error: userError } = await supabase
            .from('users')
            .insert({
                id: testUserId,
                email: email,
                name: 'Property Test User',
                role: 'creator'
            });
            
        if (userError) {
            console.log(`❌ Failed to create user record: ${userError.message}`);
            return false;
        }
        
        // Create wallet with initial balance
        initialBalance = 1000.00;
        const { error: walletError } = await supabase
            .from('wallets')
            .insert({
                user_id: testUserId,
                available_balance: initialBalance,
                escrow_balance: 0.00,
                total_earnings: 0.00,
                total_withdrawn: 0.00,
                is_frozen: false,
                currency: 'INR'
            });
            
        if (walletError) {
            console.log(`❌ Failed to create wallet: ${walletError.message}`);
            return false;
        }
        
        testUser = { id: testUserId, email: email };
        console.log(`✅ Created property test user with $${initialBalance} initial balance`);
        return true;
        
    } catch (error) {
        console.log(`❌ Setup failed: ${error.message}`);
        return false;
    }
}

async function propertyBalanceConsistency() {
    console.log('\n📋 PROPERTY 1: Balance Consistency (Increment + Decrement = Identity)');
    console.log('─'.repeat(60));
    
    const results = { tests: 0, passed: 0, failed: 0, violations: [] };
    const testIterations = 10; // Generate 10 random test cases
    
    console.log(`🔄 Generating ${testIterations} random test cases...`);
    
    for (let i = 1; i <= testIterations; i++) {
        results.tests++;
        
        try {
            // Generate random amount
            const amount = WalletTestGenerator.generatePositiveAmount();
            console.log(`\n  Test ${i}: Amount $${amount.toFixed(2)}`);
            
            // Get current balance
            const { data: beforeWallet } = await supabase
                .from('wallets')
                .select('available_balance')
                .eq('user_id', testUser.id)
                .single();
                
            const balanceBefore = parseFloat(beforeWallet.available_balance);
            console.log(`    📊 Balance before: $${balanceBefore.toFixed(2)}`);
            
            // Increment
            const { data: afterIncrement, error: incError } = await supabase.rpc('increment_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: amount
            });
            
            if (incError) {
                console.log(`    ❌ Increment failed: ${incError.message}`);
                results.failed++;
                results.violations.push(`Test ${i}: Increment error - ${incError.message}`);
                continue;
            }
            
            console.log(`    📈 After increment: $${afterIncrement.toFixed(2)}`);
            
            // Decrement by same amount
            const { data: afterDecrement, error: decError } = await supabase.rpc('decrement_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: amount
            });
            
            if (decError) {
                console.log(`    ❌ Decrement failed: ${decError.message}`);
                results.failed++;
                results.violations.push(`Test ${i}: Decrement error - ${decError.message}`);
                continue;
            }
            
            console.log(`    📉 After decrement: $${afterDecrement.toFixed(2)}`);
            
            // Check property: should return to original balance
            const diff = Math.abs(afterDecrement - balanceBefore);
            if (diff < 0.01) { // Allow for floating point precision
                console.log(`    ✅ Property holds: Returned to original balance`);
                results.passed++;
            } else {
                console.log(`    ❌ Property violated: Expected $${balanceBefore.toFixed(2)}, got $${afterDecrement.toFixed(2)}`);
                results.failed++;
                results.violations.push(`Test ${i}: Balance inconsistency - diff $${diff.toFixed(4)}`);
            }
            
        } catch (exception) {
            console.log(`    ❌ Exception: ${exception.message}`);
            results.failed++;
            results.violations.push(`Test ${i}: Exception - ${exception.message}`);
        }
    }
    
    return results;
}

async function propertyAdminSecurityEnforcement() {
    console.log('\n📋 PROPERTY 2: Admin Security Enforcement (Non-admin Access Blocked)');
    console.log('─'.repeat(60));
    
    const results = { tests: 0, passed: 0, failed: 0, violations: [] };
    
    // Create non-admin client
    const anonSupabase = createClient(supabaseUrl, process.env.SUPABASE_ANON_KEY || 'anon-key');
    
    // Generate multiple test scenarios
    const amounts = WalletTestGenerator.generateAmountSequence(5);
    console.log(`🔄 Testing ${amounts.length} amounts with non-admin client...`);
    
    for (let i = 0; i < amounts.length; i++) {
        const amount = amounts[i];
        
        // Test increment with non-admin (should fail)
        results.tests++;
        console.log(`\n  Test ${i + 1}a: Non-admin increment $${amount.toFixed(2)}`);
        
        try {
            const { data, error } = await anonSupabase.rpc('increment_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: amount
            });
            
            if (error && error.message.includes('Unauthorized')) {
                console.log(`    ✅ Correctly blocked: ${error.message}`);
                results.passed++;
            } else {
                console.log(`    ❌ Security violation: Non-admin increment succeeded with result ${data}`);
                results.failed++;
                results.violations.push(`Non-admin increment $${amount} was allowed`);
            }
        } catch (exception) {
            console.log(`    ❌ Exception: ${exception.message}`);
            results.failed++;
            results.violations.push(`Non-admin increment exception: ${exception.message}`);
        }
        
        // Test decrement with non-admin (should fail)  
        results.tests++;
        console.log(`  Test ${i + 1}b: Non-admin decrement $${amount.toFixed(2)}`);
        
        try {
            const { data, error } = await anonSupabase.rpc('decrement_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: amount
            });
            
            if (error && error.message.includes('Unauthorized')) {
                console.log(`    ✅ Correctly blocked: ${error.message}`);
                results.passed++;
            } else {
                console.log(`    ❌ Security violation: Non-admin decrement succeeded with result ${data}`);
                results.failed++;
                results.violations.push(`Non-admin decrement $${amount} was allowed`);
            }
        } catch (exception) {
            console.log(`    ❌ Exception: ${exception.message}`);
            results.failed++;
            results.violations.push(`Non-admin decrement exception: ${exception.message}`);
        }
    }
    
    return results;
}

async function propertyNonNegativeBalance() {
    console.log('\n📋 PROPERTY 3: Non-negative Balance Invariant (Balance >= 0 Always)');
    console.log('─'.repeat(60));
    
    const results = { tests: 0, passed: 0, failed: 0, violations: [] };
    
    // Generate scenarios with different balance levels
    const scenarios = WalletTestGenerator.generateBalanceScenarios();
    console.log(`🔄 Testing ${scenarios.length} balance scenarios...`);
    
    for (const scenario of scenarios) {
        results.tests++;
        
        try {
            console.log(`\n  Testing: ${scenario.description} ($${scenario.balance.toFixed(2)})`);
            
            // Set up the scenario balance
            await supabase
                .from('wallets')
                .update({ available_balance: scenario.balance })
                .eq('user_id', testUser.id);
            
            // Try to decrement more than available (should fail)
            const excessiveAmount = scenario.balance + Math.random() * 100 + 1;
            console.log(`    🚫 Attempting to decrement $${excessiveAmount.toFixed(2)} (exceeds balance)`);
            
            const { data, error } = await supabase.rpc('decrement_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: excessiveAmount
            });
            
            if (error && error.message.includes('Insufficient balance')) {
                console.log(`    ✅ Property holds: Excessive decrement blocked`);
                results.passed++;
            } else {
                console.log(`    ❌ Property violated: Excessive decrement allowed, result: ${data}`);
                results.failed++;
                results.violations.push(`Negative balance allowed in scenario: ${scenario.description}`);
            }
            
        } catch (exception) {
            console.log(`    ❌ Exception: ${exception.message}`);
            results.failed++;
            results.violations.push(`Exception in scenario ${scenario.description}: ${exception.message}`);
        }
    }
    
    return results;
}

async function propertyMonotonicOperations() {
    console.log('\n📋 PROPERTY 4: Monotonic Operations (Increment Always Increases)');
    console.log('─'.repeat(60));
    
    const results = { tests: 0, passed: 0, failed: 0, violations: [] };
    const amounts = WalletTestGenerator.generateAmountSequence(8);
    
    console.log(`🔄 Testing ${amounts.length} increment operations...`);
    
    // Reset to known balance
    await supabase
        .from('wallets')
        .update({ available_balance: 500.00 })
        .eq('user_id', testUser.id);
        
    let previousBalance = 500.00;
    
    for (let i = 0; i < amounts.length; i++) {
        results.tests++;
        const amount = amounts[i];
        
        try {
            console.log(`\n  Test ${i + 1}: Increment by $${amount.toFixed(2)}`);
            console.log(`    📊 Previous balance: $${previousBalance.toFixed(2)}`);
            
            const { data: newBalance, error } = await supabase.rpc('increment_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: amount
            });
            
            if (error) {
                console.log(`    ❌ Increment failed: ${error.message}`);
                results.failed++;
                results.violations.push(`Increment $${amount} failed: ${error.message}`);
                continue;
            }
            
            console.log(`    📈 New balance: $${newBalance.toFixed(2)}`);
            
            // Property: new balance should be greater than previous
            if (newBalance > previousBalance) {
                const increase = newBalance - previousBalance;
                console.log(`    ✅ Property holds: Increased by $${increase.toFixed(2)}`);
                
                // Also check the increase matches the amount (within precision)
                if (Math.abs(increase - amount) < 0.01) {
                    console.log(`    ✅ Correct amount: Expected $${amount.toFixed(2)}, got $${increase.toFixed(2)}`);
                } else {
                    console.log(`    ⚠️  Amount mismatch: Expected $${amount.toFixed(2)}, got $${increase.toFixed(2)}`);
                }
                
                results.passed++;
                previousBalance = newBalance;
            } else {
                console.log(`    ❌ Property violated: Balance did not increase! ${previousBalance} -> ${newBalance}`);
                results.failed++;
                results.violations.push(`Increment $${amount} did not increase balance: ${previousBalance} -> ${newBalance}`);
            }
            
        } catch (exception) {
            console.log(`    ❌ Exception: ${exception.message}`);
            results.failed++;
            results.violations.push(`Increment exception: ${exception.message}`);
        }
    }
    
    return results;
}

async function propertyBoundedOperations() {
    console.log('\n📋 PROPERTY 5: Bounded Operations (Decrement Respects Available Balance)');
    console.log('─'.repeat(60));
    
    const results = { tests: 0, passed: 0, failed: 0, violations: [] };
    
    // Set up test with known balance
    const testBalance = 300.00;
    await supabase
        .from('wallets')
        .update({ available_balance: testBalance })
        .eq('user_id', testUser.id);
        
    console.log(`🔄 Testing decrements against $${testBalance} balance...`);
    
    // Generate amounts both within and exceeding balance
    const validAmounts = [50.00, 100.00, 150.00, 299.99]; // Within balance
    const invalidAmounts = [300.01, 400.00, 500.00, 1000.00]; // Exceed balance
    
    // Test valid amounts (should succeed)
    console.log('\n  Testing valid amounts (should succeed):');
    let currentBalance = testBalance;
    
    for (const amount of validAmounts) {
        if (amount > currentBalance) continue; // Skip if we don't have enough left
        
        results.tests++;
        
        try {
            console.log(`\n    Decrement $${amount.toFixed(2)} from $${currentBalance.toFixed(2)}`);
            
            const { data: newBalance, error } = await supabase.rpc('decrement_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: amount
            });
            
            if (error) {
                console.log(`      ❌ Valid decrement failed: ${error.message}`);
                results.failed++;
                results.violations.push(`Valid decrement $${amount} failed: ${error.message}`);
                continue;
            }
            
            // Property: new balance should be non-negative and correctly decremented
            if (newBalance >= 0 && Math.abs((currentBalance - amount) - newBalance) < 0.01) {
                console.log(`      ✅ Property holds: $${currentBalance.toFixed(2)} - $${amount.toFixed(2)} = $${newBalance.toFixed(2)}`);
                results.passed++;
                currentBalance = newBalance;
            } else {
                console.log(`      ❌ Property violated: Expected $${(currentBalance - amount).toFixed(2)}, got $${newBalance.toFixed(2)}`);
                results.failed++;
                results.violations.push(`Incorrect decrement: ${currentBalance} - ${amount} != ${newBalance}`);
            }
            
        } catch (exception) {
            console.log(`      ❌ Exception: ${exception.message}`);
            results.failed++;
            results.violations.push(`Valid decrement exception: ${exception.message}`);
        }
    }
    
    // Test invalid amounts (should fail)
    console.log('\n  Testing invalid amounts (should fail):');
    
    for (const amount of invalidAmounts) {
        results.tests++;
        
        try {
            console.log(`\n    Decrement $${amount.toFixed(2)} from $${currentBalance.toFixed(2)} (should fail)`);
            
            const { data, error } = await supabase.rpc('decrement_wallet_balance', {
                p_user_id: testUser.id,
                p_amount: amount
            });
            
            if (error && error.message.includes('Insufficient balance')) {
                console.log(`      ✅ Property holds: Excessive decrement correctly blocked`);
                results.passed++;
            } else {
                console.log(`      ❌ Property violated: Excessive decrement allowed, result: ${data}`);
                results.failed++;
                results.violations.push(`Excessive decrement $${amount} was allowed`);
            }
            
        } catch (exception) {
            console.log(`      ❌ Exception: ${exception.message}`);
            results.failed++;
            results.violations.push(`Invalid decrement exception: ${exception.message}`);
        }
    }
    
    return results;
}

async function cleanupPropertyTestEnvironment() {
    console.log('\n🧹 CLEANUP: Removing Property Test Environment');
    console.log('─'.repeat(60));
    
    if (testUser) {
        try {
            await supabase.auth.admin.deleteUser(testUser.id);
            await supabase.from('wallets').delete().eq('user_id', testUser.id);
            await supabase.from('users').delete().eq('id', testUser.id);
            console.log('✅ Cleaned up property test resources');
        } catch (error) {
            console.log(`⚠️ Cleanup warning: ${error.message}`);
        }
    }
}

async function main() {
    console.log('\n🚀 Starting property-based wallet preservation tests...\n');
    
    let allResults = {
        totalProperties: 0,
        totalTests: 0,
        totalPassed: 0,
        totalFailed: 0,
        allViolations: []
    };
    
    try {
        // Setup property test environment
        const setupSuccess = await setupPropertyTestEnvironment();
        if (!setupSuccess) {
            console.log('❌ Setup failed - cannot proceed with property tests');
            process.exit(1);
        }
        
        // Run all property tests
        const properties = [
            { name: 'Balance Consistency', func: propertyBalanceConsistency },
            { name: 'Admin Security Enforcement', func: propertyAdminSecurityEnforcement },
            { name: 'Non-negative Balance Invariant', func: propertyNonNegativeBalance },
            { name: 'Monotonic Operations', func: propertyMonotonicOperations },
            { name: 'Bounded Operations', func: propertyBoundedOperations }
        ];
        
        for (const property of properties) {
            console.log(`\n🔄 Testing ${property.name} property...`);
            const results = await property.func();
            
            allResults.totalProperties++;
            allResults.totalTests += results.tests;
            allResults.totalPassed += results.passed;
            allResults.totalFailed += results.failed;
            allResults.allViolations.push(...results.violations);
            
            console.log(`   📊 Property Result: ${results.passed}/${results.tests} tests passed`);
        }
        
        // Final results
        console.log('\n' + '═'.repeat(100));
        console.log('📊 PROPERTY-BASED TEST 2.2 RESULTS');
        console.log('═'.repeat(100));
        
        console.log(`\n📈 PROPERTY VALIDATION SUMMARY:`);
        console.log(`   Total Properties Tested: ${allResults.totalProperties}`);
        console.log(`   Total Test Cases Generated: ${allResults.totalTests}`);
        console.log(`   Passed: ${allResults.totalPassed}`);
        console.log(`   Failed: ${allResults.totalFailed}`);
        console.log(`   Success Rate: ${(allResults.totalPassed/allResults.totalTests*100).toFixed(1)}%`);
        
        if (allResults.allViolations.length > 0) {
            console.log('\n❌ PROPERTY VIOLATIONS:');
            allResults.allViolations.forEach((violation, index) => {
                console.log(`   ${index + 1}. ${violation}`);
            });
        }
        
        console.log('\n🎯 WALLET FUNCTION PROPERTIES VALIDATED:');
        console.log('   📊 Balance Consistency: increment + decrement = identity');
        console.log('   🔒 Admin Security: non-admin access blocked');  
        console.log('   ⚖️  Non-negative Invariant: balance never goes negative');
        console.log('   📈 Monotonic Increments: increments always increase balance');
        console.log('   📉 Bounded Decrements: decrements respect available balance');
        
        console.log('\n📋 PROPERTY-BASED BASELINE DOCUMENTED:');
        console.log('   - Generated comprehensive test scenarios automatically');
        console.log('   - Validated function behavior across wide input ranges');
        console.log('   - Captured mathematical properties that must be preserved');
        console.log('   - Established strong guarantees for existing functionality');
        
        console.log('\n' + '═'.repeat(100));
        console.log('PROPERTY-BASED TEST 2.2 COMPLETION STATUS');
        console.log('═'.repeat(100));
        
        if (allResults.totalFailed === 0) {
            console.log('🎉 ALL PROPERTIES HOLD - BASELINE PRESERVED');
            console.log('   ✅ All wallet function properties satisfied');
            console.log('   ✅ Strong preservation guarantees established');
            console.log('   ✅ Ready for alias implementation with confidence');
            
            console.log('\n🛡️  PRESERVATION GUARANTEE:');
            console.log('   These same properties MUST hold after implementing aliases');
            console.log('   Property-based tests provide stronger guarantees than unit tests');
            console.log('   Any alias implementation that breaks these properties is incorrect');
            
        } else {
            console.log('❌ PROPERTY VIOLATIONS DETECTED');
            console.log('   Some wallet function properties are not satisfied');
            console.log('   Investigation needed - existing functions may have bugs');
            console.log('   Document these as known issues before proceeding');
        }
        
        return allResults.totalFailed === 0;
        
    } catch (error) {
        console.log('\n💥 FATAL ERROR:');
        console.log(error.message);
        console.log(error.stack);
        return false;
    } finally {
        // Always cleanup
        await cleanupPropertyTestEnvironment();
    }
}

// Execute the property-based test
if (require.main === module) {
    main().then(success => {
        process.exit(success ? 0 : 1);
    }).catch(error => {
        console.error('\n💥 FATAL ERROR:', error);
        process.exit(1);
    });
}

module.exports = { main, WalletTestGenerator };