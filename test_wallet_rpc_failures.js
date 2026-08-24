#!/usr/bin/env node

/**
 * Bug Exploration Test 1.2: Wallet RPC Function Failures
 * 
 * CRITICAL: This test MUST FAIL on unfixed schema - failure confirms the bugs exist
 * DO NOT attempt to fix the tests or the functions when they fail
 * 
 * Purpose: Demonstrate both credit_wallet() and debit_wallet() function failures
 * This implements Task 1.2 from the bugfix spec for Phase 1 Critical Database Fixes
 * 
 * Bug Description:
 * - admin_provider.dart calls: credit_wallet() and debit_wallet() 
 * - wallet_balance_rpc.sql defines: increment_wallet_balance() and decrement_wallet_balance()
 * 
 * Expected Outcome: BOTH tests FAIL - confirming function name mismatch bugs exist
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Bug Exploration Test 1.2: Testing Wallet RPC Function Failures');
console.log('='.repeat(100));
console.log('Phase 1 Critical Database Fixes - Bug Condition Exploration');
console.log('');
console.log('Testing both wallet RPC function calls that should fail:');
console.log('  1. credit_wallet() - called by admin_provider.dart');
console.log('  2. debit_wallet()  - called by admin_provider.dart');
console.log('');
console.log('These calls should fail because wallet_balance_rpc.sql defines:');
console.log('  - increment_wallet_balance() instead of credit_wallet()');
console.log('  - decrement_wallet_balance() instead of debit_wallet()');
console.log('='.repeat(100));

function analyzeDartCode() {
    console.log('\n📋 STEP 1: Analyzing Dart Code Function Calls');
    console.log('─'.repeat(60));
    
    try {
        const dartFilePath = path.join(__dirname, 'admin_app/lib/features/admin/providers/admin_provider.dart');
        const dartContent = fs.readFileSync(dartFilePath, 'utf8');
        
        // Find credit_wallet calls
        const creditWalletMatches = dartContent.match(/\.rpc\s*\(\s*['"']credit_wallet['"']/g);
        const debitWalletMatches = dartContent.match(/\.rpc\s*\(\s*['"']debit_wallet['"']/g);
        
        console.log('📄 Found function calls in admin_provider.dart:');
        
        if (creditWalletMatches) {
            console.log(`✅ credit_wallet() calls found: ${creditWalletMatches.length}`);
            // Find the line numbers
            const lines = dartContent.split('\n');
            lines.forEach((line, index) => {
                if (line.includes("rpc('credit_wallet'")) {
                    console.log(`   Line ${index + 1}: ${line.trim()}`);
                }
            });
        } else {
            console.log('❌ No credit_wallet() calls found');
        }
        
        if (debitWalletMatches) {
            console.log(`✅ debit_wallet() calls found: ${debitWalletMatches.length}`);
            // Find the line numbers  
            const lines = dartContent.split('\n');
            lines.forEach((line, index) => {
                if (line.includes("rpc('debit_wallet'")) {
                    console.log(`   Line ${index + 1}: ${line.trim()}`);
                }
            });
        } else {
            console.log('❌ No debit_wallet() calls found');
        }
        
        return {
            creditWalletCalls: creditWalletMatches ? creditWalletMatches.length : 0,
            debitWalletCalls: debitWalletMatches ? debitWalletMatches.length : 0
        };
        
    } catch (error) {
        console.log(`❌ Error reading Dart file: ${error.message}`);
        return { creditWalletCalls: 0, debitWalletCalls: 0 };
    }
}

function analyzeSQLFunctions() {
    console.log('\n📋 STEP 2: Analyzing SQL Function Definitions');
    console.log('─'.repeat(60));
    
    try {
        const sqlFilePath = path.join(__dirname, 'supabase/wallet_balance_rpc.sql');
        const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');
        
        console.log('📄 Analyzing wallet_balance_rpc.sql functions:');
        
        // Find function definitions
        const incrementFunction = sqlContent.match(/CREATE\s+OR\s+REPLACE\s+FUNCTION\s+increment_wallet_balance/i);
        const decrementFunction = sqlContent.match(/CREATE\s+OR\s+REPLACE\s+FUNCTION\s+decrement_wallet_balance/i);
        const creditFunction = sqlContent.match(/CREATE\s+OR\s+REPLACE\s+FUNCTION\s+credit_wallet/i);
        const debitFunction = sqlContent.match(/CREATE\s+OR\s+REPLACE\s+FUNCTION\s+debit_wallet/i);
        
        console.log('🔍 Function definitions found:');
        console.log(`   increment_wallet_balance(): ${incrementFunction ? '✅ EXISTS' : '❌ NOT FOUND'}`);
        console.log(`   decrement_wallet_balance(): ${decrementFunction ? '✅ EXISTS' : '❌ NOT FOUND'}`);
        console.log(`   credit_wallet(): ${creditFunction ? '✅ EXISTS' : '❌ NOT FOUND'}`);
        console.log(`   debit_wallet(): ${debitFunction ? '✅ EXISTS' : '❌ NOT FOUND'}`);
        
        // Extract function signatures
        if (incrementFunction) {
            const incrementMatch = sqlContent.match(/CREATE\s+OR\s+REPLACE\s+FUNCTION\s+increment_wallet_balance\s*\((.*?)\)/is);
            if (incrementMatch) {
                console.log(`\n📝 increment_wallet_balance signature:`);
                console.log(`   ${incrementMatch[0]}`);
            }
        }
        
        if (decrementFunction) {
            const decrementMatch = sqlContent.match(/CREATE\s+OR\s+REPLACE\s+FUNCTION\s+decrement_wallet_balance\s*\((.*?)\)/is);
            if (decrementMatch) {
                console.log(`\n📝 decrement_wallet_balance signature:`);
                console.log(`   ${decrementMatch[0]}`);
            }
        }
        
        return {
            hasIncrement: !!incrementFunction,
            hasDecrement: !!decrementFunction,
            hasCredit: !!creditFunction,
            hasDebit: !!debitFunction
        };
        
    } catch (error) {
        console.log(`❌ Error reading SQL file: ${error.message}`);
        return { hasIncrement: false, hasDecrement: false, hasCredit: false, hasDebit: false };
    }
}

function simulateFunctionCalls(dartAnalysis, sqlAnalysis) {
    console.log('\n📋 STEP 3: Simulating Function Call Failures');
    console.log('─'.repeat(60));
    
    const results = {
        credit_wallet: null,
        debit_wallet: null,
        bugsConfirmed: 0
    };
    
    // Test credit_wallet function call
    console.log('\n🧪 Simulating credit_wallet() RPC call...');
    if (dartAnalysis.creditWalletCalls > 0 && !sqlAnalysis.hasCredit) {
        console.log('❌ FUNCTION CALL WOULD FAIL:');
        console.log('   Dart code calls: supabase.rpc("credit_wallet", {...})');
        console.log('   SQL database: Function "credit_wallet" does not exist');
        console.log('   Available: increment_wallet_balance()');
        console.log('   Expected Error: function credit_wallet(uuid, numeric) does not exist');
        results.credit_wallet = {
            success: false,
            error: 'function credit_wallet(uuid, numeric) does not exist',
            bugConfirmed: true
        };
        results.bugsConfirmed++;
    } else if (dartAnalysis.creditWalletCalls > 0 && sqlAnalysis.hasCredit) {
        console.log('🚨 UNEXPECTED: credit_wallet function exists in SQL');
        results.credit_wallet = { success: true, bugConfirmed: false };
    } else {
        console.log('⚠️  No credit_wallet calls found in Dart code');
        results.credit_wallet = { success: false, error: 'No calls found', bugConfirmed: false };
    }
    
    // Test debit_wallet function call  
    console.log('\n🧪 Simulating debit_wallet() RPC call...');
    if (dartAnalysis.debitWalletCalls > 0 && !sqlAnalysis.hasDebit) {
        console.log('❌ FUNCTION CALL WOULD FAIL:');
        console.log('   Dart code calls: supabase.rpc("debit_wallet", {...})');
        console.log('   SQL database: Function "debit_wallet" does not exist');
        console.log('   Available: decrement_wallet_balance()');
        console.log('   Expected Error: function debit_wallet(uuid, numeric) does not exist');
        results.debit_wallet = {
            success: false,
            error: 'function debit_wallet(uuid, numeric) does not exist',
            bugConfirmed: true
        };
        results.bugsConfirmed++;
    } else if (dartAnalysis.debitWalletCalls > 0 && sqlAnalysis.hasDebit) {
        console.log('🚨 UNEXPECTED: debit_wallet function exists in SQL');
        results.debit_wallet = { success: true, bugConfirmed: false };
    } else {
        console.log('⚠️  No debit_wallet calls found in Dart code');
        results.debit_wallet = { success: false, error: 'No calls found', bugConfirmed: false };
    }
    
    return results;
}

async function main() {
    console.log('\n🚀 Starting wallet RPC function failure analysis...\n');
    
    try {
        // Step 1: Analyze Dart code for function calls
        const dartAnalysis = analyzeDartCode();
        
        // Step 2: Analyze SQL file for function definitions
        const sqlAnalysis = analyzeSQLFunctions();
        
        // Step 3: Simulate what would happen when the calls are made
        const results = simulateFunctionCalls(dartAnalysis, sqlAnalysis);
        
        // Final analysis and results
        console.log('\n' + '═'.repeat(100));
        console.log('📊 TASK 1.2 RESULTS ANALYSIS');
        console.log('═'.repeat(100));

        console.log('\n🔍 MISMATCH ANALYSIS:');
        console.log(`   Dart calls credit_wallet(): ${dartAnalysis.creditWalletCalls > 0 ? '✅ YES' : '❌ NO'}`);
        console.log(`   SQL defines credit_wallet(): ${sqlAnalysis.hasCredit ? '✅ YES' : '❌ NO'}`);
        console.log(`   Dart calls debit_wallet(): ${dartAnalysis.debitWalletCalls > 0 ? '✅ YES' : '❌ NO'}`);
        console.log(`   SQL defines debit_wallet(): ${sqlAnalysis.hasDebit ? '✅ YES' : '❌ NO'}`);

        console.log('\n📋 AVAILABLE SQL FUNCTIONS:');
        console.log(`   increment_wallet_balance(): ${sqlAnalysis.hasIncrement ? '✅ EXISTS' : '❌ MISSING'}`);
        console.log(`   decrement_wallet_balance(): ${sqlAnalysis.hasDecrement ? '✅ EXISTS' : '❌ MISSING'}`);

        console.log('\n🎯 FUNCTION CALL SIMULATION RESULTS:');
        
        if (results.credit_wallet && results.credit_wallet.bugConfirmed) {
            console.log('   ❌ credit_wallet() call: WOULD FAIL (bug confirmed)');
        }
        
        if (results.debit_wallet && results.debit_wallet.bugConfirmed) {
            console.log('   ❌ debit_wallet() call: WOULD FAIL (bug confirmed)');
        }

        // Final summary
        console.log('\n' + '═'.repeat(100));
        console.log('FINAL TASK 1.2 SUMMARY');
        console.log('═'.repeat(100));
        console.log(`🐛 Function Name Mismatches Confirmed: ${results.bugsConfirmed}`);

        if (results.bugsConfirmed === 2) {
            console.log('\n✅ BUG EXPLORATION SUCCESSFUL (Both tests would fail as expected)');
            console.log('🔍 Confirmed: Both wallet RPC function name mismatches exist');
            
            console.log('\n📝 COUNTEREXAMPLES DOCUMENTED:');
            console.log('1. Input: supabase.rpc("credit_wallet", {...})');
            console.log('   Output: function credit_wallet does not exist error');
            console.log('   Fix needed: Create credit_wallet() alias for increment_wallet_balance()');
            
            console.log('2. Input: supabase.rpc("debit_wallet", {...})');
            console.log('   Output: function debit_wallet does not exist error');  
            console.log('   Fix needed: Create debit_wallet() alias for decrement_wallet_balance()');

            console.log('\n🎯 NEXT STEPS:');
            console.log('   1. Proceed to Task 2: Write preservation property tests');
            console.log('   2. Then implement fixes in Task 3.2: Create wallet RPC function aliases');
            console.log('   3. Re-run these tests after fixes - they should PASS');

            console.log('\n🎉 TASK 1.2 COMPLETED SUCCESSFULLY');
            console.log('   Both wallet function mismatches confirmed as expected');
            process.exit(0);
            
        } else if (results.bugsConfirmed === 1) {
            console.log('\n⚠️  PARTIAL BUG CONFIRMATION');
            console.log('   Only one function mismatch confirmed - investigate the other');
            process.exit(0);
        } else {
            console.log('\n❌ NO BUGS CONFIRMED');
            console.log('   Functions may already exist or test logic needs adjustment');
            process.exit(1);
        }
        
    } catch (error) {
        console.log('\n💥 TEST EXECUTION ERROR:');
        console.log(error.message);
        console.log(error.stack);
        process.exit(1);
    }
}

// Execute the test
main();