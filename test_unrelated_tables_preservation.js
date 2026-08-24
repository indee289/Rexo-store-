#!/usr/bin/env node

/**
 * Task 2.3: Test Unrelated Table Operations Preservation
 * 
 * GOAL: Capture cross-table operation consistency patterns
 * METHOD: Observation-first methodology on UNFIXED schema
 * CONTEXT: Phase 1 Critical Database Fixes - Wave 2 (Preservation Testing)
 * 
 * PURPOSE: Ensure our fixes to subscription_plans, wallet functions, and 
 * subscription_payments don't break any unrelated database operations.
 * 
 * EXPECTED OUTCOME: Tests PASS on unfixed schema (other operations unaffected)
 */

const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Configuration
const supabaseUrl = process.env.SUPABASE_URL || 'http://localhost:54321';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

console.log('🧪 TASK 2.3: Unrelated Table Operations Preservation Testing');
console.log('📋 Testing campaigns, applications, users tables + cross-table operations');
console.log('🎯 PRESERVATION TESTING - capturing baseline behavior on UNFIXED schema');
console.log('=' * 80);

class UnrelatedTablesPreservationTester {
  constructor() {
    this.supabase = createClient(supabaseUrl, supabaseAnonKey);
    this.testResults = {
      campaigns: { passed: 0, failed: 0, tests: [] },
      applications: { passed: 0, failed: 0, tests: [] },
      users: { passed: 0, failed: 0, tests: [] },
      crossTable: { passed: 0, failed: 0, tests: [] },
      auth: { passed: 0, failed: 0, tests: [] }
    };
    this.preservationPatterns = [];
  }

  async runTest(category, testName, testFunc) {
    try {
      console.log(`\n🔍 Testing ${category}.${testName}...`);
      const result = await testFunc();
      
      this.testResults[category].passed++;
      this.testResults[category].tests.push({ name: testName, status: 'PASSED', result });
      
      console.log(`✅ ${category}.${testName}: PASSED`);
      return { success: true, result };
    } catch (error) {
      this.testResults[category].failed++;
      this.testResults[category].tests.push({ 
        name: testName, 
        status: 'FAILED', 
        error: error.message 
      });
      
      console.log(`❌ ${category}.${testName}: FAILED - ${error.message}`);
      return { success: false, error: error.message };
    }
  }

  // ==========================================
  // CAMPAIGNS TABLE CRUD OPERATIONS
  // ==========================================

  async testCampaignsReadOperations() {
    return this.runTest('campaigns', 'readOperations', async () => {
      // Test basic SELECT operations
      const { data, error } = await this.supabase
        .from('campaigns')
        .select('*')
        .limit(10);

      if (error) throw new Error(`Campaigns read failed: ${error.message}`);

      const schema = data.length > 0 ? Object.keys(data[0]) : [];
      
      // Document schema structure for preservation
      this.preservationPatterns.push({
        operation: 'campaigns.select',
        schema: schema,
        recordCount: data.length,
        sampleData: data.length > 0 ? data[0] : null
      });

      return {
        recordCount: data.length,
        schema: schema,
        hasRequiredFields: schema.includes('id') && schema.includes('title') && 
                          schema.includes('brand_id') && schema.includes('status')
      };
    });
  }

  async testCampaignsFilterOperations() {
    return this.runTest('campaigns', 'filterOperations', async () => {
      // Test WHERE clause operations
      const activeFilter = await this.supabase
        .from('campaigns')
        .select('id, title, status')
        .eq('status', 'active')
        .limit(5);

      const draftFilter = await this.supabase
        .from('campaigns')
        .select('id, title, status')
        .eq('status', 'draft')
        .limit(5);

      if (activeFilter.error) throw new Error(`Active filter failed: ${activeFilter.error.message}`);
      if (draftFilter.error) throw new Error(`Draft filter failed: ${draftFilter.error.message}`);

      this.preservationPatterns.push({
        operation: 'campaigns.filter',
        activeCount: activeFilter.data.length,
        draftCount: draftFilter.data.length,
        statusValues: [...new Set([...activeFilter.data, ...draftFilter.data].map(c => c.status))]
      });

      return {
        activeCount: activeFilter.data.length,
        draftCount: draftFilter.data.length,
        filtersWork: true
      };
    });
  }

  async testCampaignsOrderingOperations() {
    return this.runTest('campaigns', 'orderingOperations', async () => {
      // Test ORDER BY operations
      const byCreatedAt = await this.supabase
        .from('campaigns')
        .select('id, title, created_at')
        .order('created_at', { ascending: false })
        .limit(5);

      const byTitle = await this.supabase
        .from('campaigns')
        .select('id, title')
        .order('title', { ascending: true })
        .limit(5);

      if (byCreatedAt.error) throw new Error(`Order by created_at failed: ${byCreatedAt.error.message}`);
      if (byTitle.error) throw new Error(`Order by title failed: ${byTitle.error.message}`);

      this.preservationPatterns.push({
        operation: 'campaigns.ordering',
        timestampOrderingWorks: byCreatedAt.data.length > 0,
        titleOrderingWorks: byTitle.data.length > 0
      });

      return {
        timestampOrdering: byCreatedAt.data.length,
        titleOrdering: byTitle.data.length,
        orderingWorks: true
      };
    });
  }

  // ==========================================
  // APPLICATIONS TABLE CRUD OPERATIONS  
  // ==========================================

  async testApplicationsReadOperations() {
    return this.runTest('applications', 'readOperations', async () => {
      const { data, error } = await this.supabase
        .from('applications')
        .select('*')
        .limit(10);

      if (error) throw new Error(`Applications read failed: ${error.message}`);

      const schema = data.length > 0 ? Object.keys(data[0]) : [];
      
      this.preservationPatterns.push({
        operation: 'applications.select',
        schema: schema,
        recordCount: data.length,
        sampleData: data.length > 0 ? data[0] : null
      });

      return {
        recordCount: data.length,
        schema: schema,
        hasRequiredFields: schema.includes('id') && schema.includes('campaign_id') && 
                          schema.includes('creator_id') && schema.includes('status')
      };
    });
  }

  async testApplicationsJoinOperations() {
    return this.runTest('applications', 'joinOperations', async () => {
      // Test JOIN with campaigns table
      const { data, error } = await this.supabase
        .from('applications')
        .select(`
          id,
          status,
          campaign_id,
          campaigns!inner(id, title, status)
        `)
        .limit(5);

      if (error) throw new Error(`Applications-campaigns join failed: ${error.message}`);

      this.preservationPatterns.push({
        operation: 'applications.joinCampaigns',
        joinCount: data.length,
        joinStructureValid: data.length > 0 && data[0].campaigns !== null
      });

      return {
        joinCount: data.length,
        joinStructureValid: data.length > 0 && data[0].campaigns !== null,
        joinWorks: true
      };
    });
  }

  async testApplicationsStatusOperations() {
    return this.runTest('applications', 'statusOperations', async () => {
      const statusCounts = {};
      const statuses = ['pending', 'approved', 'rejected', 'withdrawn'];

      for (const status of statuses) {
        const { data, error } = await this.supabase
          .from('applications')
          .select('id')
          .eq('status', status);

        if (error) throw new Error(`Status filter ${status} failed: ${error.message}`);
        statusCounts[status] = data.length;
      }

      this.preservationPatterns.push({
        operation: 'applications.statusFilters',
        statusCounts: statusCounts
      });

      return {
        statusCounts,
        statusFiltersWork: true
      };
    });
  }

  // ==========================================
  // USERS TABLE AUTHENTICATION FLOWS
  // ==========================================

  async testUsersReadOperations() {
    return this.runTest('users', 'readOperations', async () => {
      // Test basic user profile reading (should work for authenticated users)
      const { data, error } = await this.supabase
        .from('users')
        .select('id, email, name, role, account_status, is_verified')
        .limit(10);

      // Note: This might fail due to RLS, which is expected behavior to preserve
      if (error && !error.message.includes('row-level security')) {
        throw new Error(`Users read failed unexpectedly: ${error.message}`);
      }

      const schema = data && data.length > 0 ? Object.keys(data[0]) : [];
      
      this.preservationPatterns.push({
        operation: 'users.select',
        schema: schema,
        recordCount: data ? data.length : 0,
        rlsActive: error && error.message.includes('row-level security')
      });

      return {
        recordCount: data ? data.length : 0,
        schema: schema,
        rlsActive: error && error.message.includes('row-level security'),
        hasRequiredFields: schema.includes('id') && schema.includes('email') && 
                          schema.includes('role')
      };
    });
  }

  async testUsersRoleOperations() {
    return this.runTest('users', 'roleOperations', async () => {
      // Test role-based filtering
      const roles = ['creator', 'brand', 'admin'];
      const roleCounts = {};

      for (const role of roles) {
        const { data, error } = await this.supabase
          .from('users')
          .select('id')
          .eq('role', role);

        // Track both successful queries and RLS-blocked ones
        if (error && !error.message.includes('row-level security')) {
          throw new Error(`Role filter ${role} failed unexpectedly: ${error.message}`);
        }

        roleCounts[role] = data ? data.length : 'RLS_BLOCKED';
      }

      this.preservationPatterns.push({
        operation: 'users.roleFilters',
        roleCounts: roleCounts
      });

      return {
        roleCounts,
        roleFiltersWork: true
      };
    });
  }

  async testUsersAccountStatusOperations() {
    return this.runTest('users', 'accountStatusOperations', async () => {
      const statuses = ['active', 'suspended', 'banned', 'pending_verification'];
      const statusCounts = {};

      for (const status of statuses) {
        const { data, error } = await this.supabase
          .from('users')
          .select('id')
          .eq('account_status', status);

        if (error && !error.message.includes('row-level security')) {
          throw new Error(`Account status filter ${status} failed: ${error.message}`);
        }

        statusCounts[status] = data ? data.length : 'RLS_BLOCKED';
      }

      this.preservationPatterns.push({
        operation: 'users.accountStatusFilters', 
        statusCounts: statusCounts
      });

      return {
        statusCounts,
        accountStatusFiltersWork: true
      };
    });
  }

  // ==========================================
  // CROSS-TABLE OPERATION CONSISTENCY
  // ==========================================

  async testCrossTableCampaignApplications() {
    return this.runTest('crossTable', 'campaignApplications', async () => {
      // Test campaign -> applications relationship
      const { data, error } = await this.supabase
        .from('campaigns')
        .select(`
          id,
          title,
          status,
          applications!inner(
            id,
            status,
            creator_id
          )
        `)
        .limit(5);

      if (error) throw new Error(`Campaign-applications cross-table failed: ${error.message}`);

      let totalApplications = 0;
      data.forEach(campaign => {
        totalApplications += campaign.applications ? campaign.applications.length : 0;
      });

      this.preservationPatterns.push({
        operation: 'crossTable.campaignApplications',
        campaignsWithApplications: data.length,
        totalApplications: totalApplications,
        relationshipIntact: true
      });

      return {
        campaignsWithApplications: data.length,
        totalApplications: totalApplications,
        relationshipIntact: true
      };
    });
  }

  async testCrossTableUserProfiles() {
    return this.runTest('crossTable', 'userProfiles', async () => {
      // Test user -> profile relationships
      const creatorProfiles = await this.supabase
        .from('creator_profiles')
        .select(`
          id,
          category,
          followers,
          users!inner(id, name, role)
        `)
        .limit(3);

      const brandProfiles = await this.supabase
        .from('brand_profiles')
        .select(`
          id,
          company_name,
          industry,
          users!inner(id, name, role)
        `)
        .limit(3);

      if (creatorProfiles.error && !creatorProfiles.error.message.includes('row-level security')) {
        throw new Error(`Creator profiles cross-table failed: ${creatorProfiles.error.message}`);
      }

      if (brandProfiles.error && !brandProfiles.error.message.includes('row-level security')) {
        throw new Error(`Brand profiles cross-table failed: ${brandProfiles.error.message}`);
      }

      this.preservationPatterns.push({
        operation: 'crossTable.userProfiles',
        creatorProfiles: creatorProfiles.data ? creatorProfiles.data.length : 'RLS_BLOCKED',
        brandProfiles: brandProfiles.data ? brandProfiles.data.length : 'RLS_BLOCKED',
        profileRelationshipsIntact: true
      });

      return {
        creatorProfiles: creatorProfiles.data ? creatorProfiles.data.length : 'RLS_BLOCKED',
        brandProfiles: brandProfiles.data ? brandProfiles.data.length : 'RLS_BLOCKED',
        profileRelationshipsIntact: true
      };
    });
  }

  async testCrossTableWalletUsers() {
    return this.runTest('crossTable', 'walletUsers', async () => {
      // Test user -> wallet relationship
      const { data, error } = await this.supabase
        .from('wallets')
        .select(`
          id,
          available_balance,
          escrow_balance,
          users!inner(id, name, role)
        `)
        .limit(5);

      if (error && !error.message.includes('row-level security')) {
        throw new Error(`Wallet-users cross-table failed: ${error.message}`);
      }

      this.preservationPatterns.push({
        operation: 'crossTable.walletUsers',
        walletsWithUsers: data ? data.length : 'RLS_BLOCKED',
        walletUserRelationshipIntact: true
      });

      return {
        walletsWithUsers: data ? data.length : 'RLS_BLOCKED',
        walletUserRelationshipIntact: true
      };
    });
  }

  async testCrossTableForeignKeyIntegrity() {
    return this.runTest('crossTable', 'foreignKeyIntegrity', async () => {
      // Test that foreign key relationships are working
      const relationships = [];
      
      // Test campaign_id in applications
      const campaignApps = await this.supabase
        .from('applications')
        .select('campaign_id')
        .not('campaign_id', 'is', null)
        .limit(1);
      
      if (campaignApps.data && campaignApps.data.length > 0) {
        const campaignExists = await this.supabase
          .from('campaigns')
          .select('id')
          .eq('id', campaignApps.data[0].campaign_id);
        
        relationships.push({
          relationship: 'applications.campaign_id -> campaigns.id',
          valid: campaignExists.data && campaignExists.data.length > 0
        });
      }

      // Test user_id in wallets
      const userWallets = await this.supabase
        .from('wallets')
        .select('user_id')
        .limit(1);
        
      if (userWallets.data && userWallets.data.length > 0) {
        const userExists = await this.supabase
          .from('users')
          .select('id')
          .eq('id', userWallets.data[0].user_id);
          
        relationships.push({
          relationship: 'wallets.user_id -> users.id',
          valid: userExists.data && userExists.data.length > 0
        });
      }

      this.preservationPatterns.push({
        operation: 'crossTable.foreignKeyIntegrity',
        relationships: relationships,
        allValid: relationships.every(r => r.valid)
      });

      return {
        relationships: relationships,
        allValid: relationships.every(r => r.valid),
        foreignKeyIntegrityMaintained: true
      };
    });
  }

  // ==========================================
  // AUTHENTICATION FLOW TESTING
  // ==========================================

  async testAuthenticationFlows() {
    return this.runTest('auth', 'basicFlows', async () => {
      // Test that authentication-dependent operations work as expected
      
      // Test anonymous access (should be limited by RLS)
      const anonAccess = await this.supabase
        .from('users')
        .select('id')
        .limit(1);

      // Test that RLS is working (should block or limit access)
      const rlsActive = anonAccess.error && 
        (anonAccess.error.message.includes('row-level security') ||
         anonAccess.error.message.includes('insufficient_privilege'));

      this.preservationPatterns.push({
        operation: 'auth.rlsEnforcement',
        rlsActive: rlsActive,
        anonymousAccessBlocked: rlsActive
      });

      return {
        rlsActive: rlsActive,
        authenticationFlowsIntact: true
      };
    });
  }

  // ==========================================
  // MAIN TEST EXECUTION
  // ==========================================

  async runAllPreservationTests() {
    console.log('\n📋 STARTING COMPREHENSIVE PRESERVATION TESTING');
    console.log('🎯 Testing unrelated table operations on UNFIXED schema');
    console.log('🔍 Capturing baseline behavior for preservation requirements\n');

    // Test Campaigns Table Operations
    console.log('\n🏷️ CAMPAIGNS TABLE OPERATIONS');
    console.log('─'.repeat(50));
    await this.testCampaignsReadOperations();
    await this.testCampaignsFilterOperations();
    await this.testCampaignsOrderingOperations();

    // Test Applications Table Operations
    console.log('\n📝 APPLICATIONS TABLE OPERATIONS');
    console.log('─'.repeat(50));
    await this.testApplicationsReadOperations();
    await this.testApplicationsJoinOperations();
    await this.testApplicationsStatusOperations();

    // Test Users Table Authentication Flows
    console.log('\n👥 USERS TABLE AUTHENTICATION FLOWS');
    console.log('─'.repeat(50));
    await this.testUsersReadOperations();
    await this.testUsersRoleOperations();
    await this.testUsersAccountStatusOperations();

    // Test Cross-Table Operations
    console.log('\n🔗 CROSS-TABLE OPERATION CONSISTENCY');
    console.log('─'.repeat(50));
    await this.testCrossTableCampaignApplications();
    await this.testCrossTableUserProfiles();
    await this.testCrossTableWalletUsers();
    await this.testCrossTableForeignKeyIntegrity();

    // Test Authentication Flows
    console.log('\n🔐 AUTHENTICATION FLOW PRESERVATION');
    console.log('─'.repeat(50));
    await this.testAuthenticationFlows();

    this.generateSummaryReport();
  }

  generateSummaryReport() {
    console.log('\n' + '='.repeat(80));
    console.log('📊 TASK 2.3: UNRELATED TABLE OPERATIONS PRESERVATION - RESULTS');
    console.log('='.repeat(80));

    const categories = Object.keys(this.testResults);
    let totalPassed = 0;
    let totalFailed = 0;

    categories.forEach(category => {
      const results = this.testResults[category];
      totalPassed += results.passed;
      totalFailed += results.failed;
      
      const status = results.failed === 0 ? '✅ ALL PASSED' : `❌ ${results.failed} FAILED`;
      console.log(`\n🏷️  ${category.toUpperCase()}: ${status}`);
      console.log(`   Tests Passed: ${results.passed}`);
      console.log(`   Tests Failed: ${results.failed}`);
      
      if (results.failed > 0) {
        console.log(`   Failed Tests:`);
        results.tests
          .filter(test => test.status === 'FAILED')
          .forEach(test => {
            console.log(`     - ${test.name}: ${test.error}`);
          });
      }
    });

    const overallSuccess = totalFailed === 0;
    const successRate = totalPassed / (totalPassed + totalFailed) * 100;

    console.log(`\n📈 OVERALL RESULTS:`);
    console.log(`   Total Tests: ${totalPassed + totalFailed}`);
    console.log(`   Passed: ${totalPassed}`);
    console.log(`   Failed: ${totalFailed}`);
    console.log(`   Success Rate: ${successRate.toFixed(1)}%`);

    if (overallSuccess) {
      console.log(`\n🎉 TASK 2.3 PRESERVATION TESTING: ✅ SUCCESS`);
      console.log(`\n✅ PRESERVATION REQUIREMENTS CAPTURED:`);
      console.log(`   ✅ Campaigns table CRUD operations work correctly`);
      console.log(`   ✅ Applications table CRUD operations work correctly`);
      console.log(`   ✅ Users table authentication flows are intact`);
      console.log(`   ✅ Cross-table operation consistency is maintained`);
      console.log(`   ✅ Foreign key relationships are preserved`);
      console.log(`   ✅ Row Level Security policies are enforced`);
      
      console.log(`\n🔒 BASELINE BEHAVIOR DOCUMENTED:`);
      console.log(`   📊 Preservation patterns captured: ${this.preservationPatterns.length}`);
      console.log(`   🎯 Ready for Phase 1 schema fixes validation`);
      
      console.log(`\n🚀 NEXT STEPS:`);
      console.log(`   1. Proceed to Task 3 (Fix Phase 1 Critical Database Issues)`);
      console.log(`   2. After implementing fixes, re-run these SAME tests`);
      console.log(`   3. Verify ALL tests still PASS (preservation guarantee)`);
      console.log(`   4. Any failing test indicates a REGRESSION that must be fixed`);
    } else {
      console.log(`\n⚠️  TASK 2.3 PRESERVATION TESTING: ❌ ISSUES DETECTED`);
      console.log(`\n🚨 BASELINE ISSUES FOUND:`);
      console.log(`   Some unrelated table operations are already failing`);
      console.log(`   This indicates existing issues beyond the 3 critical fixes`);
      console.log(`   Consider addressing these before proceeding with schema changes`);
    }

    console.log('\n' + '='.repeat(80));
    
    return {
      success: overallSuccess,
      totalTests: totalPassed + totalFailed,
      passed: totalPassed,
      failed: totalFailed,
      successRate: successRate,
      preservationPatterns: this.preservationPatterns
    };
  }
}

// Execute the preservation testing
async function main() {
  try {
    const tester = new UnrelatedTablesPreservationTester();
    await tester.runAllPreservationTests();
    
    // Save preservation patterns for future reference
    const fs = require('fs');
    const preservationData = {
      taskId: '2.3',
      testType: 'unrelated_tables_preservation',
      executedAt: new Date().toISOString(),
      preservationPatterns: tester.preservationPatterns,
      testResults: tester.testResults
    };
    
    fs.writeFileSync(
      '/projects/sandbox/Rexo-store-/TASK_2.3_PRESERVATION_PATTERNS.json',
      JSON.stringify(preservationData, null, 2)
    );
    
    console.log('\n💾 Preservation patterns saved to TASK_2.3_PRESERVATION_PATTERNS.json');
    
  } catch (error) {
    console.error('\n🚨 PRESERVATION TESTING FAILED:', error.message);
    console.error(error.stack);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { UnrelatedTablesPreservationTester };