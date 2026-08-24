#!/usr/bin/env node
/**
 * TASK 4.1: Complete Subscription Workflow Integration Test
 * 
 * Tests the end-to-end subscription workflow ensuring all three critical 
 * database fixes work together properly:
 * 
 * 1. Migration 1: subscription_plans table has both interval and duration_days columns
 * 2. Migration 2: wallet function aliases (credit_wallet/debit_wallet) work
 * 3. Migration 3: subscription_payments table exists and works
 * 
 * WORKFLOW TESTED:
 * A. User views subscription plans (uses both columns from Migration 1)
 * B. User submits subscription payment (uses table from Migration 3) 
 * C. Admin approves payment and credits wallet (uses aliases from Migration 2)
 * D. Subscription becomes active in user_subscriptions table
 * E. Complete integration validation
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// Supabase configuration
const SUPABASE_URL = 'https://mdvbqaswygzzhiggqwio.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kdmJxYXN3eWd6emhpZ2dxd2lvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjY1NzUxNDAsImV4cCI6MjA0MjE1MTE0MH0.GdFG5NFJ8x5-Kf_nQj3DyakOd9ZzlN6Toeo_icgeSpY';

const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Test user IDs (using real UUIDs for testing)
const TEST_USER_ID = '11111111-1111-1111-1111-111111111111';
const ADMIN_USER_ID = '22222222-2222-2222-2222-222222222222';

// Test data
const TEST_PLAN = {
  id: 'test-plan-subscription-workflow',
  name: 'Integration Test Pro Plan',
  price: 299.00,
  duration_days: 30,
  interval: 'month',
  is_active: true,
  features: JSON.stringify(['Test feature 1', 'Test feature 2'])
};

const TEST_PAYMENT = {
  plan_name: 'Integration Test Pro Plan',
  amount: 299.00,
  duration_days: 30,
  payment_method: 'UPI',
  transaction_ref: 'TEST_TXN_4_1_' + Date.now(),
  proof_url: 'https://example.com/proof.jpg'
};

/**
 * Test Results Tracking
 */
let testResults = {
  totalTests: 0,
  passedTests: 0,
  failedTests: 0,
  results: [],
  workflow: {
    planViewingWorking: false,
    paymentSubmissionWorking: false,
    adminApprovalWorking: false,
    subscriptionActivationWorking: false,
    integrationComplete: false
  }
};

function logTest(testName, passed, details, error = null) {
  testResults.totalTests++;
  if (passed) {
    testResults.passedTests++;
    console.log(`✅ ${testName}`);
  } else {
    testResults.failedTests++;
    console.log(`❌ ${testName}`);
    if (error) console.log(`   Error: ${error.message}`);
  }
  
  testResults.results.push({
    test: testName,
    passed,
    details,
    error: error?.message,
    timestamp: new Date().toISOString()
  });
}

/**
 * STEP A: Test Subscription Plans Viewing (Migration 1 Validation)
 */
async function testSubscriptionPlansViewing() {
  console.log('\n=== STEP A: Testing Subscription Plans Viewing (Migration 1) ===');
  
  try {
    // First, ensure test plan exists with both columns
    await client
      .from('subscription_plans')
      .upsert(TEST_PLAN);
    
    console.log('Test plan inserted/updated successfully');
    
    // Test 1: Query subscription_plans with both interval and duration_days columns
    const { data: plans, error: plansError } = await client
      .from('subscription_plans')
      .select('id, name, price, duration_days, interval, is_active, features')
      .eq('is_active', true)
      .order('price', { ascending: true });
    
    if (plansError) {
      logTest(
        'A.1 - Query subscription plans with both columns',
        false,
        'Failed to query subscription_plans table',
        plansError
      );
      return false;
    }
    
    // Verify both columns exist in results
    const testPlan = plans.find(p => p.id === TEST_PLAN.id);
    const hasBothColumns = testPlan && 
                          typeof testPlan.duration_days === 'number' && 
                          typeof testPlan.interval === 'string';
    
    logTest(
      'A.1 - Query subscription plans with both columns',
      hasBothColumns,
      `Found ${plans.length} plans, test plan has both columns: ${hasBothColumns}`
    );
    
    // Test 2: Verify interval column values are valid
    const validIntervals = plans.every(p => 
      ['month', 'year', 'week', 'day'].includes(p.interval)
    );
    
    logTest(
      'A.2 - Verify interval column has valid values',
      validIntervals,
      `All plans have valid interval values: ${validIntervals}`
    );
    
    // Test 3: Verify duration_days column is numeric
    const validDurations = plans.every(p => 
      typeof p.duration_days === 'number' && p.duration_days > 0
    );
    
    logTest(
      'A.3 - Verify duration_days column is numeric and positive',
      validDurations,
      `All plans have valid duration_days values: ${validDurations}`
    );
    
    if (hasBothColumns && validIntervals && validDurations) {
      testResults.workflow.planViewingWorking = true;
      return true;
    }
    
    return false;
    
  } catch (error) {
    logTest(
      'A.1 - Query subscription plans with both columns',
      false,
      'Exception occurred during subscription plans viewing test',
      error
    );
    return false;
  }
}

/**
 * STEP B: Test Subscription Payment Submission (Migration 3 Validation)
 */
async function testSubscriptionPaymentSubmission() {
  console.log('\n=== STEP B: Testing Subscription Payment Submission (Migration 3) ===');
  
  try {
    // Test 1: Insert subscription payment into subscription_payments table
    const paymentData = {
      user_id: TEST_USER_ID,
      plan_id: TEST_PLAN.id,
      ...TEST_PAYMENT,
      status: 'pending'
    };
    
    const { data: insertData, error: insertError } = await client
      .from('subscription_payments')
      .insert(paymentData)
      .select()
      .single();
    
    if (insertError) {
      logTest(
        'B.1 - Insert subscription payment record',
        false,
        'Failed to insert into subscription_payments table',
        insertError
      );
      return { success: false, paymentId: null };
    }
    
    logTest(
      'B.1 - Insert subscription payment record',
      true,
      `Successfully inserted payment record with ID: ${insertData.id}`
    );
    
    // Test 2: Query subscription payment back
    const { data: queryData, error: queryError } = await client
      .from('subscription_payments')
      .select('*')
      .eq('id', insertData.id)
      .single();
    
    if (queryError || !queryData) {
      logTest(
        'B.2 - Query subscription payment record',
        false,
        'Failed to query subscription_payments table',
        queryError
      );
      return { success: false, paymentId: insertData.id };
    }
    
    // Verify all required fields are present
    const requiredFields = ['user_id', 'plan_id', 'amount', 'duration_days', 
                          'payment_method', 'transaction_ref', 'status'];
    const hasAllFields = requiredFields.every(field => queryData[field] !== null);
    
    logTest(
      'B.2 - Query subscription payment record',
      hasAllFields,
      `Payment record has all required fields: ${hasAllFields}`
    );
    
    // Test 3: Verify status is 'pending'
    const isPendingStatus = queryData.status === 'pending';
    
    logTest(
      'B.3 - Verify payment status is pending',
      isPendingStatus,
      `Payment status is 'pending': ${isPendingStatus}`
    );
    
    if (hasAllFields && isPendingStatus) {
      testResults.workflow.paymentSubmissionWorking = true;
      return { success: true, paymentId: insertData.id };
    }
    
    return { success: false, paymentId: insertData.id };
    
  } catch (error) {
    logTest(
      'B.1 - Insert subscription payment record',
      false,
      'Exception occurred during subscription payment submission test',
      error
    );
    return { success: false, paymentId: null };
  }
}

/**
 * STEP C: Test Admin Payment Approval and Wallet Credit (Migration 2 Validation)
 */
async function testAdminPaymentApprovalAndWalletCredit(paymentId) {
  console.log('\n=== STEP C: Testing Admin Payment Approval and Wallet Credit (Migration 2) ===');
  
  if (!paymentId) {
    logTest(
      'C.1 - Approve subscription payment',
      false,
      'No payment ID provided for approval test'
    );
    return { success: false, subscriptionId: null };
  }
  
  try {
    // First ensure user has a wallet
    await client
      .from('wallets')
      .upsert({
        user_id: TEST_USER_ID,
        balance: 0.00
      });
    
    // Test 1: Update payment status to approved
    const { data: updateData, error: updateError } = await client
      .from('subscription_payments')
      .update({
        status: 'approved',
        admin_notes: 'Integration test approval',
        processed_at: new Date().toISOString()
      })
      .eq('id', paymentId)
      .select()
      .single();
    
    if (updateError) {
      logTest(
        'C.1 - Approve subscription payment',
        false,
        'Failed to update payment status to approved',
        updateError
      );
      return { success: false, subscriptionId: null };
    }
    
    logTest(
      'C.1 - Approve subscription payment',
      true,
      `Successfully approved payment ${paymentId}`
    );
    
    // Test 2: Credit wallet using credit_wallet alias function (Migration 2)
    const { data: creditData, error: creditError } = await client
      .rpc('credit_wallet', {
        p_user_id: TEST_USER_ID,
        p_amount: 100.00  // Bonus credit for approved subscription
      });
    
    if (creditError) {
      logTest(
        'C.2 - Credit wallet using alias function',
        false,
        'Failed to credit wallet using credit_wallet function',
        creditError
      );
      return { success: false, subscriptionId: null };
    }
    
    logTest(
      'C.2 - Credit wallet using alias function',
      true,
      `Successfully credited wallet. New balance: ${creditData}`
    );
    
    // Test 3: Create active subscription in user_subscriptions
    const subscriptionData = {
      user_id: TEST_USER_ID,
      plan_id: TEST_PLAN.id,
      plan_name: TEST_PLAN.name,
      amount: TEST_PAYMENT.amount,
      duration_days: TEST_PAYMENT.duration_days,
      status: 'active',
      starts_at: new Date().toISOString(),
      ends_at: new Date(Date.now() + (TEST_PAYMENT.duration_days * 24 * 60 * 60 * 1000)).toISOString()
    };
    
    const { data: subData, error: subError } = await client
      .from('user_subscriptions')
      .insert(subscriptionData)
      .select()
      .single();
    
    if (subError) {
      logTest(
        'C.3 - Create active subscription',
        false,
        'Failed to create active subscription',
        subError
      );
      return { success: false, subscriptionId: null };
    }
    
    logTest(
      'C.3 - Create active subscription',
      true,
      `Successfully created active subscription with ID: ${subData.id}`
    );
    
    testResults.workflow.adminApprovalWorking = true;
    testResults.workflow.subscriptionActivationWorking = true;
    
    return { success: true, subscriptionId: subData.id };
    
  } catch (error) {
    logTest(
      'C.1 - Approve subscription payment',
      false,
      'Exception occurred during admin approval and wallet credit test',
      error
    );
    return { success: false, subscriptionId: null };
  }
}

/**
 * STEP D: Test Complete Integration Validation
 */
async function testCompleteIntegration(subscriptionId) {
  console.log('\n=== STEP D: Testing Complete Integration Validation ===');
  
  try {
    // Test 1: Verify subscription is active and properly linked
    const { data: subData, error: subError } = await client
      .from('user_subscriptions')
      .select('*')
      .eq('user_id', TEST_USER_ID)
      .eq('status', 'active')
      .order('created_at', { ascending: false })
      .limit(1);
    
    if (subError || !subData || subData.length === 0) {
      logTest(
        'D.1 - Verify active subscription exists',
        false,
        'No active subscription found for test user',
        subError
      );
      return false;
    }
    
    const subscription = subData[0];
    const hasRequiredFields = subscription.plan_id && 
                            subscription.plan_name && 
                            subscription.amount && 
                            subscription.duration_days;
    
    logTest(
      'D.1 - Verify active subscription exists',
      hasRequiredFields,
      `Active subscription found with all required fields: ${hasRequiredFields}`
    );
    
    // Test 2: Verify wallet balance was credited
    const { data: walletData, error: walletError } = await client
      .from('wallets')
      .select('balance')
      .eq('user_id', TEST_USER_ID)
      .single();
    
    if (walletError || !walletData) {
      logTest(
        'D.2 - Verify wallet balance was credited',
        false,
        'Failed to query wallet balance',
        walletError
      );
      return false;
    }
    
    const hasPositiveBalance = walletData.balance > 0;
    
    logTest(
      'D.2 - Verify wallet balance was credited',
      hasPositiveBalance,
      `Wallet balance: ${walletData.balance} (positive: ${hasPositiveBalance})`
    );
    
    // Test 3: Verify subscription payment is marked as approved
    const { data: paymentData, error: paymentError } = await client
      .from('subscription_payments')
      .select('status, processed_at')
      .eq('user_id', TEST_USER_ID)
      .eq('transaction_ref', TEST_PAYMENT.transaction_ref)
      .single();
    
    if (paymentError || !paymentData) {
      logTest(
        'D.3 - Verify payment approval status',
        false,
        'Failed to query subscription payment',
        paymentError
      );
      return false;
    }
    
    const isApproved = paymentData.status === 'approved' && paymentData.processed_at;
    
    logTest(
      'D.3 - Verify payment approval status',
      isApproved,
      `Payment status: ${paymentData.status}, processed: ${!!paymentData.processed_at}`
    );
    
    // Test 4: Test debit_wallet function for completeness
    const { data: debitData, error: debitError } = await client
      .rpc('debit_wallet', {
        p_user_id: TEST_USER_ID,
        p_amount: 10.00  // Small debit to test the function
      });
    
    if (debitError) {
      logTest(
        'D.4 - Test debit_wallet alias function',
        false,
        'Failed to debit wallet using debit_wallet function',
        debitError
      );
    } else {
      logTest(
        'D.4 - Test debit_wallet alias function',
        true,
        `Successfully debited wallet. New balance: ${debitData}`
      );
    }
    
    if (hasRequiredFields && hasPositiveBalance && isApproved) {
      testResults.workflow.integrationComplete = true;
      return true;
    }
    
    return false;
    
  } catch (error) {
    logTest(
      'D.1 - Verify active subscription exists',
      false,
      'Exception occurred during complete integration validation',
      error
    );
    return false;
  }
}

/**
 * Cleanup Test Data
 */
async function cleanupTestData() {
  console.log('\n=== Cleaning Up Test Data ===');
  
  try {
    // Clean up subscription payments
    await client
      .from('subscription_payments')
      .delete()
      .eq('transaction_ref', TEST_PAYMENT.transaction_ref);
    
    // Clean up user subscriptions
    await client
      .from('user_subscriptions')
      .delete()
      .eq('user_id', TEST_USER_ID);
    
    // Clean up test subscription plan
    await client
      .from('subscription_plans')
      .delete()
      .eq('id', TEST_PLAN.id);
    
    // Reset test user wallet balance
    await client
      .from('wallets')
      .update({ balance: 0.00 })
      .eq('user_id', TEST_USER_ID);
    
    console.log('✅ Test data cleanup completed');
    
  } catch (error) {
    console.log('❌ Test data cleanup failed:', error.message);
  }
}

/**
 * Save Test Results
 */
function saveTestResults() {
  const results = {
    ...testResults,
    summary: {
      testExecutionTime: new Date().toISOString(),
      totalTests: testResults.totalTests,
      passedTests: testResults.passedTests,
      failedTests: testResults.failedTests,
      successRate: testResults.totalTests > 0 ? 
                   ((testResults.passedTests / testResults.totalTests) * 100).toFixed(1) : 0
    },
    workflowValidation: {
      allStepsWorking: Object.values(testResults.workflow).every(step => step === true),
      stepsStatus: testResults.workflow
    }
  };
  
  fs.writeFileSync(
    '/projects/sandbox/Rexo-store-/TASK_4.1_COMPLETE_SUBSCRIPTION_WORKFLOW_RESULTS.json',
    JSON.stringify(results, null, 2)
  );
}

/**
 * Main Test Execution
 */
async function runCompleteSubscriptionWorkflowTest() {
  console.log('🚀 Starting Task 4.1: Complete Subscription Workflow Integration Test');
  console.log('Testing all three critical database fixes working together...\n');
  
  try {
    // Step A: Test subscription plans viewing (Migration 1)
    const planViewingSuccess = await testSubscriptionPlansViewing();
    
    // Step B: Test subscription payment submission (Migration 3)
    const { success: paymentSuccess, paymentId } = await testSubscriptionPaymentSubmission();
    
    // Step C: Test admin approval and wallet credit (Migration 2)
    const { success: approvalSuccess, subscriptionId } = await testAdminPaymentApprovalAndWalletCredit(paymentId);
    
    // Step D: Test complete integration validation
    const integrationSuccess = await testCompleteIntegration(subscriptionId);
    
    // Cleanup
    await cleanupTestData();
    
    // Save results
    saveTestResults();
    
    // Summary
    console.log('\n' + '='.repeat(80));
    console.log('TASK 4.1 COMPLETE SUBSCRIPTION WORKFLOW TEST SUMMARY');
    console.log('='.repeat(80));
    console.log(`Total Tests: ${testResults.totalTests}`);
    console.log(`Passed: ${testResults.passedTests}`);
    console.log(`Failed: ${testResults.failedTests}`);
    console.log(`Success Rate: ${((testResults.passedTests / testResults.totalTests) * 100).toFixed(1)}%`);
    console.log('\nWorkflow Steps Status:');
    console.log(`✓ Plan Viewing (Migration 1): ${testResults.workflow.planViewingWorking ? '✅' : '❌'}`);
    console.log(`✓ Payment Submission (Migration 3): ${testResults.workflow.paymentSubmissionWorking ? '✅' : '❌'}`);
    console.log(`✓ Admin Approval (Migration 2): ${testResults.workflow.adminApprovalWorking ? '✅' : '❌'}`);
    console.log(`✓ Subscription Activation: ${testResults.workflow.subscriptionActivationWorking ? '✅' : '❌'}`);
    console.log(`✓ Complete Integration: ${testResults.workflow.integrationComplete ? '✅' : '❌'}`);
    
    const allStepsWorking = Object.values(testResults.workflow).every(step => step === true);
    
    console.log('\n' + '='.repeat(80));
    if (allStepsWorking) {
      console.log('🎉 SUCCESS: Complete subscription workflow integration test PASSED!');
      console.log('All three critical database fixes work together properly.');
    } else {
      console.log('❌ FAILURE: Complete subscription workflow integration test FAILED!');
      console.log('Some workflow steps are not working correctly.');
    }
    console.log('='.repeat(80));
    
    return allStepsWorking;
    
  } catch (error) {
    console.error('Fatal error during test execution:', error);
    await cleanupTestData();
    saveTestResults();
    return false;
  }
}

// Execute the test if run directly
if (require.main === module) {
  runCompleteSubscriptionWorkflowTest()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('Test execution failed:', error);
      process.exit(1);
    });
}

module.exports = {
  runCompleteSubscriptionWorkflowTest,
  testResults
};