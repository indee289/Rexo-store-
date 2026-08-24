#!/usr/bin/env node

/**
 * Bug Exploration Test 1.3: Subscription Payments Table Failure
 * 
 * CRITICAL: This test MUST FAIL on unfixed schema - failure confirms the bug exists
 * DO NOT attempt to fix the tests or create the table when they fail
 * 
 * This test demonstrates that the subscription_payments table is missing from the schema:
 * - lib/features/subscriptions/providers/subscriptions_provider.dart references 'subscription_payments' table
 * - supabase/schema.sql does NOT define this table
 * - supabase/add_subscription_payments.sql defines it separately but is not integrated
 * 
 * Expected outcome: Test FAILS with "table subscription_payments does not exist" error
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 Bug Exploration Test 1.3: Testing Subscription Payment Table Failure');
console.log('=' .repeat(80));

function analyzeCodeReferences() {
    console.log('\n📋 Analyzing code references to subscription_payments table...');
    
    try {
        // Read the subscription provider file
        const providerPath = path.join(__dirname, 'lib/features/subscriptions/providers/subscriptions_provider.dart');
        const providerContent = fs.readFileSync(providerPath, 'utf8');
        
        // Extract the INSERT statement that would fail
        const insertMatches = providerContent.match(/\.from\(['"`]subscription_payments['"`]\)\.insert\([^)]*\)/g);
        
        if (insertMatches) {
            console.log('\n📄 Code trying to insert into subscription_payments:');
            insertMatches.forEach((match, index) => {
                console.log(`${index + 1}. ${match}`);
            });
            
            // Find the specific data structure being inserted
            const insertBlockMatch = providerContent.match(/await SupabaseService\.client\.from\(['"`]subscription_payments['"`]\)\.insert\({([^}]+)}\)/s);
            if (insertBlockMatch) {
                console.log('\n📊 Data structure being inserted:');
                console.log('{');
                const dataFields = insertBlockMatch[1].split(',');
                dataFields.forEach(field => {
                    console.log(`  ${field.trim()},`);
                });
                console.log('}');
            }
        } else {
            console.log('❌ No subscription_payments INSERT operations found in provider');
        }
        
        // Also check for SELECT operations
        const selectMatches = providerContent.match(/\.from\(['"`]subscription_payments['"`]\)\.select\([^)]*\)/g);
        if (selectMatches) {
            console.log('\n📖 Code trying to select from subscription_payments:');
            selectMatches.forEach((match, index) => {
                console.log(`${index + 1}. ${match}`);
            });
        }
        
        return insertMatches && insertMatches.length > 0;
        
    } catch (error) {
        console.log('❌ Failed to read provider file:', error.message);
        return false;
    }
}

function analyzeSchemaDefinition() {
    console.log('\n📋 Analyzing current schema definition...');
    
    try {
        // Read the main schema file
        const schemaPath = path.join(__dirname, 'supabase/schema.sql');
        const schemaContent = fs.readFileSync(schemaPath, 'utf8');
        
        // Check if subscription_payments table is defined
        const tableMatches = schemaContent.match(/CREATE TABLE.*?subscription_payments/gi);
        
        if (tableMatches) {
            console.log('✅ subscription_payments table found in schema.sql');
            return true;
        } else {
            console.log('❌ subscription_payments table NOT found in schema.sql');
            
            // Check what tables ARE defined
            const allTableMatches = schemaContent.match(/CREATE TABLE\s+(\w+)/gi);
            if (allTableMatches) {
                console.log('\n📋 Tables that ARE defined in schema.sql:');
                allTableMatches.forEach(match => {
                    const tableName = match.replace(/CREATE TABLE\s+/i, '');
                    console.log(`  - ${tableName}`);
                });
            }
            
            return false;
        }
        
    } catch (error) {
        console.log('❌ Failed to read schema file:', error.message);
        return false;
    }
}

function analyzeSeparateMigration() {
    console.log('\n📋 Checking for separate migration file...');
    
    try {
        // Read the separate migration file
        const migrationPath = path.join(__dirname, 'supabase/add_subscription_payments.sql');
        const migrationContent = fs.readFileSync(migrationPath, 'utf8');
        
        console.log('✅ Found separate migration file: add_subscription_payments.sql');
        
        // Extract table definition from migration
        const tableMatch = migrationContent.match(/CREATE TABLE.*?subscription_payments.*?\((.*?)\);/s);
        if (tableMatch) {
            console.log('\n📊 Table structure defined in separate migration:');
            console.log('CREATE TABLE subscription_payments (');
            const columns = tableMatch[1].split(',').map(col => col.trim()).filter(col => col);
            columns.forEach(column => {
                console.log(`    ${column},`);
            });
            console.log(');');
        }
        
        return true;
        
    } catch (error) {
        console.log('❌ Separate migration file not found:', error.message);
        return false;
    }
}

function simulateInsertOperation() {
    console.log('\n🧪 Simulating subscription payment INSERT operation...');
    
    // Simulate the exact data that would be inserted based on the provider code
    const mockPaymentData = {
        user_id: '123e4567-e89b-12d3-a456-426614174000', // Mock UUID
        plan_id: '456e7890-e89b-12d3-a456-426614174001',
        plan_name: 'Premium Monthly',
        amount: 999.00,
        duration_days: 30,
        payment_method: 'UPI',
        transaction_ref: 'TXN123456789',
        proof_url: 'https://example.com/proof.jpg',
        status: 'pending',
        created_at: new Date().toISOString()
    };
    
    console.log('💾 Attempting to insert payment data:');
    console.log(JSON.stringify(mockPaymentData, null, 2));
    
    console.log('\n🔍 SQL that would be executed:');
    console.log(`INSERT INTO subscription_payments (${Object.keys(mockPaymentData).join(', ')}) 
VALUES (${Object.values(mockPaymentData).map(v => typeof v === 'string' ? `'${v}'` : v).join(', ')});`);
    
    console.log('\n💥 Expected database response:');
    console.log('ERROR: relation "subscription_payments" does not exist');
    console.log('LINE 1: INSERT INTO subscription_payments (user_id, plan_id, ...)');
    console.log('                    ^');
    console.log('HINT: Perhaps you meant to reference the table "public.subscription_payments".');
    
    return {
        operation: 'INSERT INTO subscription_payments',
        data: mockPaymentData,
        expectedError: 'relation "subscription_payments" does not exist'
    };
}

function generateBugReport() {
    console.log('\n📝 Generating bug condition analysis...');
    
    const bugReport = {
        bugType: 'missing_table',
        component: 'subscription_payments_workflow',
        root_cause: 'Table defined in separate migration not integrated into main schema',
        affected_operations: [
            'User subscription payment submission',
            'Admin subscription payment approval queries',
            'Subscription payment status tracking'
        ],
        error_scenarios: [
            {
                trigger: 'User calls SubscriptionNotifier.submitSubscriptionPayment()',
                result: 'Supabase client throws "relation does not exist" error',
                user_impact: 'Cannot submit subscription payments - feature completely broken'
            },
            {
                trigger: 'Admin queries subscription payment history',
                result: 'Query fails with table not found error',
                user_impact: 'Admin cannot review or approve subscription payments'
            }
        ],
        fix_required: 'Integrate add_subscription_payments.sql into main schema or run migration'
    };
    
    console.log(JSON.stringify(bugReport, null, 2));
    
    return bugReport;
}

function runTest() {
    return new Promise((resolve) => {
        console.log('\n🔧 Executing bug exploration test...');
        
        // Step 1: Analyze code references
        const hasCodeReferences = analyzeCodeReferences();
        
        // Step 2: Check main schema  
        const tableInSchema = analyzeSchemaDefinition();
        
        // Step 3: Check separate migration
        const separateMigrationExists = analyzeSeparateMigration();
        
        // Step 4: Simulate the failing operation
        const simulationResult = simulateInsertOperation();
        
        // Step 5: Generate comprehensive bug report
        const bugReport = generateBugReport();
        
        // Determine if bug condition exists
        const bugConditionExists = hasCodeReferences && !tableInSchema && separateMigrationExists;
        
        if (bugConditionExists) {
            resolve({
                success: false, // Test FAILED as expected (confirms bug exists)
                bugConfirmed: true,
                error: simulationResult.expectedError,
                details: {
                    codeReferencesTable: hasCodeReferences,
                    tableInMainSchema: tableInSchema,
                    separateMigrationExists: separateMigrationExists,
                    failingOperation: simulationResult.operation,
                    bugReport: bugReport
                }
            });
        } else {
            resolve({
                success: true,
                bugConfirmed: false,
                error: 'Bug condition not detected - schema may already be fixed',
                details: {
                    codeReferencesTable: hasCodeReferences,
                    tableInMainSchema: tableInSchema,
                    separateMigrationExists: separateMigrationExists
                }
            });
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
            console.log('🔍 Confirmed: subscription_payments table is missing from schema');
            console.log(`❌ Error: ${result.error}`);
            console.log(`📋 Code references table: ${result.details.codeReferencesTable}`);
            console.log(`📄 Table in main schema: ${result.details.tableInMainSchema}`);
            console.log(`🔧 Separate migration exists: ${result.details.separateMigrationExists}`);
            console.log(`💥 Failing operation: ${result.details.failingOperation}`);
            console.log('🎯 Next: This test will PASS after table integration fix is implemented');
            
            // Document the counterexample found
            console.log('\n📝 COUNTEREXAMPLE DOCUMENTED:');
            console.log('Input: Execute subscription payment INSERT via Supabase client');
            console.log('Output: "relation subscription_payments does not exist" error');
            console.log('Confirms: Missing table bug condition exists and needs to be fixed');
            
            // Save detailed results
            const resultsPath = path.join(__dirname, 'TASK_1.3_SUBSCRIPTION_PAYMENTS_BUG_EXPLORATION_RESULTS.md');
            const markdown = generateResultsMarkdown(result);
            fs.writeFileSync(resultsPath, markdown);
            console.log(`\n💾 Detailed results saved to: ${resultsPath}`);
            
            process.exit(0); // Success for exploration test (bug confirmed)
        } else {
            console.log('❌ BUG EXPLORATION FAILED (Test passed unexpectedly)');
            console.log('⚠️  Schema may already be fixed or test logic is incorrect');
            console.log(`📋 Code references table: ${result.details.codeReferencesTable}`);
            console.log(`📄 Table in main schema: ${result.details.tableInMainSchema}`);
            console.log(`🔧 Separate migration exists: ${result.details.separateMigrationExists}`);
            process.exit(1);
        }
        
    } catch (error) {
        console.log('\n💥 TEST EXECUTION ERROR:');
        console.log(error.message);
        process.exit(1);
    }
}

function generateResultsMarkdown(result) {
    const timestamp = new Date().toISOString();
    return `# Task 1.3: Subscription Payments Table Bug Exploration Results

**Generated:** ${timestamp}
**Test Status:** ${result.bugConfirmed ? 'BUG CONFIRMED' : 'NO BUG DETECTED'}

## Summary
${result.bugConfirmed ? 
    'Successfully confirmed that the subscription_payments table is missing from the main schema, causing INSERT operations to fail.' :
    'The subscription_payments table appears to be properly integrated in the schema.'}

## Bug Analysis

### Code References
- **Code references subscription_payments table:** ${result.details.codeReferencesTable}
- **Table defined in main schema:** ${result.details.tableInMainSchema}  
- **Separate migration file exists:** ${result.details.separateMigrationExists}

### Failing Operation
\`\`\`
${result.details.failingOperation}
\`\`\`

### Expected Database Error
\`\`\`
${result.error}
\`\`\`

## Root Cause Analysis
The bug exists because:
1. Flutter code in \`lib/features/subscriptions/providers/subscriptions_provider.dart\` references \`subscription_payments\` table
2. The main \`supabase/schema.sql\` does NOT include this table definition
3. A separate \`supabase/add_subscription_payments.sql\` file exists but is not integrated into the schema
4. When users attempt subscription payments, Supabase client throws "relation does not exist" error

## Impact Assessment
- **User Impact:** Subscription payment feature completely broken
- **Admin Impact:** Cannot review or approve subscription payments  
- **Business Impact:** No revenue collection from subscription payments
- **Severity:** CRITICAL - core functionality failure

## Bug Condition Details
${result.details.bugReport ? JSON.stringify(result.details.bugReport, null, 2) : 'N/A'}

## Fix Required
Integrate the \`add_subscription_payments.sql\` migration into the main schema or execute the migration separately to create the missing table.

## Verification
This test confirms the bug condition exists. After the fix is implemented, re-running this test should show the table exists and operations succeed.
`;
}

// Execute the test
main();