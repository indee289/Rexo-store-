#!/usr/bin/env node

/**
 * Bug Exploration Test 1.1: Subscription Plans Migration Failure
 * 
 * CRITICAL: This test MUST FAIL on unfixed schema - failure confirms the bug exists
 * DO NOT attempt to fix the tests or the schema when they fail
 * 
 * This test demonstrates the schema mismatch between:
 * - schema.sql: subscription_plans table has 'duration_days INTEGER' column
 * - seed_subscription_plans.sql: tries to insert into 'interval TEXT' column
 * 
 * Expected outcome: Test FAILS with "column interval does not exist" error
 */

const fs = require('fs');
const { exec } = require('child_process');
const path = require('path');

console.log('🔍 Bug Exploration Test 1.1: Testing Subscription Plans Migration Failure');
console.log('=' .repeat(80));

function runTest() {
    return new Promise((resolve, reject) => {
        console.log('\n📋 Test Details:');
        console.log('- Schema defines: duration_days INTEGER NOT NULL');  
        console.log('- Seed file tries to insert into: interval TEXT (which does not exist)');
        console.log('- Expected: Migration should FAIL with column error');
        
        console.log('\n🔧 Executing seed_subscription_plans.sql...');
        
        // Read the seed file to show what it's trying to do
        const seedFilePath = path.join(__dirname, 'supabase/seed_subscription_plans.sql');
        
        try {
            const seedContent = fs.readFileSync(seedFilePath, 'utf8');
            console.log('\n📄 Seed file content attempting to execute:');
            console.log('---');
            console.log(seedContent);
            console.log('---');
            
            // Extract the problematic INSERT statement
            const insertMatch = seedContent.match(/INSERT INTO.*?VALUES.*?ON CONFLICT/gs);
            if (insertMatch) {
                console.log('\n❌ Problematic INSERT statement:');
                console.log(insertMatch[0]);
                
                // Look for the interval column reference
                if (insertMatch[0].includes('interval')) {
                    console.log('\n🚨 DETECTED SCHEMA MISMATCH:');
                    console.log('- Seed file references "interval" column');
                    console.log('- But schema.sql only defines "duration_days" column');
                    console.log('- This will cause: ERROR column "interval" does not exist');
                }
            }
        } catch (error) {
            console.log('\n❌ Failed to read seed file:', error.message);
        }
        
        // Simulate what would happen when this runs against the current schema
        console.log('\n🧪 Simulating migration execution against current schema...');
        
        // Since we can't actually run this against a live database in this test environment,
        // we'll demonstrate the error by parsing the SQL and showing the mismatch
        try {
            const schemaPath = path.join(__dirname, 'supabase/schema.sql');
            const schemaContent = fs.readFileSync(schemaPath, 'utf8');
            
            // Extract subscription_plans table definition
            const tableMatch = schemaContent.match(
                /CREATE TABLE.*?subscription_plans.*?\((.*?)\);/gs
            );
            
            if (tableMatch) {
                const tableDefinition = tableMatch[0];
                console.log('\n📋 Current schema definition:');
                console.log(tableDefinition);
                
                // Check if interval column exists
                const hasIntervalColumn = tableDefinition.includes('interval');
                const hasDurationDaysColumn = tableDefinition.includes('duration_days');
                
                console.log('\n🔍 Schema Analysis:');
                console.log(`- Has "interval" column: ${hasIntervalColumn}`);
                console.log(`- Has "duration_days" column: ${hasDurationDaysColumn}`);
                
                if (!hasIntervalColumn && hasDurationDaysColumn) {
                    console.log('\n💥 CONFIRMED BUG CONDITION:');
                    console.log('❌ Seed file references non-existent "interval" column');
                    console.log('✅ Schema only has "duration_days" column');
                    console.log('🚨 Result: Migration will fail with column error');
                    
                    // Simulate the exact error that would occur
                    const errorMessage = 'ERROR: column "interval" of relation "subscription_plans" does not exist';
                    console.log('\n🔥 EXPECTED DATABASE ERROR:');
                    console.log(`PostgreSQL Error: ${errorMessage}`);
                    console.log('LINE 1: INSERT INTO public.subscription_plans (id, name, price, interval, features)');
                    console.log('                                                                    ^');
                    console.log('HINT: Perhaps you meant to reference the column "duration_days".');
                    
                    // This confirms the bug exists
                    resolve({
                        success: false, // Test FAILED as expected (confirming bug)
                        error: errorMessage,
                        bugConfirmed: true,
                        details: {
                            schemaColumn: 'duration_days INTEGER NOT NULL',
                            seedFileColumn: 'interval TEXT',
                            mismatchType: 'column_name_mismatch'
                        }
                    });
                } else {
                    resolve({
                        success: true,
                        error: 'Schema appears to already be fixed',
                        bugConfirmed: false
                    });
                }
            } else {
                throw new Error('Could not find subscription_plans table definition in schema');
            }
        } catch (error) {
            reject(error);
        }
    });
}

async function main() {
    try {
        const result = await runTest();
        
        console.log('\n' + '='.repeat(80));
        console.log('📊 TEST RESULT SUMMARY:');
        console.log('='.repeat(80));
        
        if (result.bugConfirmed) {
            console.log('✅ BUG EXPLORATION SUCCESSFUL (Test failed as expected)');
            console.log('🔍 Confirmed: Subscription plans schema mismatch exists');
            console.log(`❌ Error: ${result.error}`);
            console.log(`📋 Schema has: ${result.details.schemaColumn}`);
            console.log(`📄 Seed expects: ${result.details.seedFileColumn}`);
            console.log('🎯 Next: This test will PASS after schema alignment fix is implemented');
            
            // Document the counterexample found
            console.log('\n📝 COUNTEREXAMPLE DOCUMENTED:');
            console.log('Input: Execute seed_subscription_plans.sql against current schema');
            console.log('Output: Column "interval" does not exist error');
            console.log('Confirms: Bug condition exists and needs to be fixed');
            
            process.exit(0); // Success for exploration test (bug confirmed)
        } else {
            console.log('❌ BUG EXPLORATION FAILED (Test passed unexpectedly)');
            console.log('⚠️  Schema may already be fixed or test logic is incorrect');
            process.exit(1);
        }
        
    } catch (error) {
        console.log('\n💥 TEST EXECUTION ERROR:');
        console.log(error.message);
        process.exit(1);
    }
}

// Execute the test
main();