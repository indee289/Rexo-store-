#!/usr/bin/env node

/**
 * Test Script: Wallet Debit Function Failure
 * 
 * Purpose: Demonstrate that debit_wallet() function does not exist in the database
 * Bug: admin_provider.dart calls debit_wallet() but wallet_balance_rpc.sql defines decrement_wallet_balance()
 * 
 * Expected Outcome: FAILURE - "function debit_wallet does not exist" error
 * This failure confirms the bug exists and needs to be fixed.
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL || 'YOUR_SUPABASE_URL';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || 'YOUR_SUPABASE_ANON_KEY';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'YOUR_SERVICE_KEY';

console.log('='.repeat(80));
console.log('WALLET DEBIT FUNCTION FAILURE TEST');
console.log('='.repeat(80));
console.log('Testing: debit_wallet() function call');
console.log('Expected: Function does not exist error');
console.log('Bug: Dart code calls debit_wallet() but SQL defines decrement_wallet_balance()');
console.log('='.repeat(80));

async function testDebitWalletFunction() {
    try {
        // Create Supabase client with service role key for admin operations
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        // Test parameters - using dummy UUID and amount
        const testUserId = '12345678-1234-1234-1234-123456789012';
        const testAmount = 50.00;

        console.log('\n📋 Test Parameters:');
        console.log(`   User ID: ${testUserId}`);
        console.log(`   Amount: $${testAmount}`);
        console.log('\n🔄 Attempting to call debit_wallet() function...');

        // This should fail because debit_wallet function doesn't exist
        const { data, error } = await supabase.rpc('debit_wallet', {
            p_user_id: testUserId,
            p_amount: testAmount
        });

        if (error) {
            console.log('\n❌ EXPECTED FAILURE CONFIRMED:');
            console.log(`   Error Code: ${error.code}`);
            console.log(`   Error Message: ${error.message}`);
            console.log(`   Error Details: ${JSON.stringify(error.details, null, 2)}`);
            
            if (error.message.toLowerCase().includes('function') && 
                error.message.toLowerCase().includes('does not exist')) {
                console.log('\n✅ BUG CONFIRMED: debit_wallet function does not exist');
                console.log('   This proves the function name mismatch bug exists');
                console.log('   Dart code: calls debit_wallet()'); 
                console.log('   SQL schema: defines decrement_wallet_balance()');
                return false; // Expected failure
            } else {
                console.log('\n⚠️  UNEXPECTED ERROR TYPE');
                console.log('   Expected "function does not exist" but got different error');
                return false;
            }
        } else {
            console.log('\n🚨 UNEXPECTED SUCCESS:');
            console.log('   The debit_wallet function call succeeded!');
            console.log('   This means the function might already exist or there is another issue');
            console.log(`   Response data: ${JSON.stringify(data, null, 2)}`);
            return true; // Unexpected success
        }

    } catch (exception) {
        console.log('\n💥 EXCEPTION CAUGHT:');
        console.log(`   Exception Type: ${exception.constructor.name}`);
        console.log(`   Exception Message: ${exception.message}`);
        console.log(`   Exception Stack: ${exception.stack}`);
        return false;
    }
}

async function main() {
    console.log('\n🚀 Starting wallet debit function test...\n');
    
    const success = await testDebitWalletFunction();
    
    console.log('\n' + '='.repeat(80));
    console.log('TEST RESULTS SUMMARY');
    console.log('='.repeat(80));
    
    if (success) {
        console.log('❌ TEST FAILED: Function call succeeded unexpectedly');
        console.log('   Investigation needed: debit_wallet function might already exist');
        console.log('   or the environment is configured differently than expected');
        process.exit(1);
    } else {
        console.log('✅ TEST PASSED: Function call failed as expected');  
        console.log('   Bug confirmed: debit_wallet function does not exist');
        console.log('   Ready to proceed with fixing the function name mismatch');
        process.exit(0);
    }
}

if (require.main === module) {
    main().catch(error => {
        console.error('\n💥 FATAL ERROR:', error);
        process.exit(1);
    });
}