import fs from 'fs';
import path from 'path';

console.log('====================================================');
console.log('REXO STORE AUTOMATED SECURITY & PENETRATION AUDIT');
console.log('====================================================\n');

// 1. Secret Exposure Scanner
console.log('--- 1. SECRET EXPOSURE SCAN ---');
const secretRegexes = [
  { name: 'R2 Secret Access Key', regex: /R2_SECRET_ACCESS_KEY\s*=\s*['"][^'"]+['"]/i },
  { name: 'Supabase Service Role Key', regex: /SUPABASE_SERVICE_ROLE_KEY\s*=\s*['"][^'"]+['"]/i },
  { name: 'Gemini API Key Hardcoded', regex: /AIzaSy[A-Za-z0-9_-]{33}/ },
  { name: 'Generic Secret Pattern', regex: /VITE_R2_SECRET_ACCESS_KEY/ },
  { name: 'Private Key PEM', regex: /-----BEGIN PRIVATE KEY-----/ },
  { name: 'Stripe/Payment Secret', regex: /sk_live_[0-9a-zA-Z]{24}/ }
];

function scanDirectory(dirPath, allowedFiles = []) {
  let matches = [];
  if (!fs.existsSync(dirPath)) return matches;
  const items = fs.readdirSync(dirPath, { withFileTypes: true });

  for (const item of items) {
    const fullPath = path.join(dirPath, item.name);
    if (item.isDirectory()) {
      if (item.name !== 'node_modules' && item.name !== '.git') {
        matches = matches.concat(scanDirectory(fullPath, allowedFiles));
      }
    } else {
      if (allowedFiles.includes(fullPath)) continue;
      const content = fs.readFileSync(fullPath, 'utf8');
      for (const rule of secretRegexes) {
        if (rule.regex.test(content)) {
          matches.push({ file: fullPath, secretType: rule.name });
        }
      }
    }
  }
  return matches;
}

// Allowed in supabase/.env.example and GITHUB_SECRETS.md as placeholder variable names
const clientMatches = scanDirectory('./src');
const distMatches = scanDirectory('./dist');
const publicMatches = scanDirectory('./public');
const androidMatches = scanDirectory('./android');

console.log(`Scan src/ directory leaks: ${clientMatches.length}`);
console.log(`Scan dist/ bundle leaks: ${distMatches.length}`);
console.log(`Scan public/ assets leaks: ${publicMatches.length}`);
console.log(`Scan android/ bundle leaks: ${androidMatches.length}`);

if (clientMatches.length === 0 && distMatches.length === 0 && androidMatches.length === 0) {
  console.log('RESULT: PASS - No hardcoded secrets found in client or compiled bundles.\n');
} else {
  console.log('RESULT: FAIL - Potential secret leaks found:', { clientMatches, distMatches, androidMatches }, '\n');
}

// 2. Edge Function Analysis
console.log('--- 2. EDGE FUNCTIONS CODE AUDIT ---');
const functionsDir = './supabase/functions';
if (fs.existsSync(functionsDir)) {
  const funcs = fs.readdirSync(functionsDir);
  console.log('Found Edge Functions:', funcs);
  for (const fn of funcs) {
    const fnPath = path.join(functionsDir, fn, 'index.ts');
    if (fs.existsSync(fnPath)) {
      const code = fs.readFileSync(fnPath, 'utf8');
      const hasAuth = code.includes('auth.getUser()') || code.includes('Authorization');
      const hasAdminCheck = code.includes("role === 'admin'") || code.includes('userData?.role === \'admin\'') || code.includes('isSystemAdmin');
      console.log(`Function [${fn}]: Auth check: ${hasAuth ? 'YES' : 'NO'}, Admin validation: ${hasAdminCheck ? 'YES' : 'N/A'}`);
    }
  }
}
console.log('');

// 3. RLS Schema Audit
console.log('--- 3. SUPABASE RLS SCHEMA AUDIT ---');
const schemaPath = './supabase/schema.sql';
if (fs.existsSync(schemaPath)) {
  const schemaSql = fs.readFileSync(schemaPath, 'utf8');
  const rlsEnabledCount = (schemaSql.match(/ENABLE ROW LEVEL SECURITY/g) || []).length;
  const policyCount = (schemaSql.match(/CREATE POLICY/g) || []).length;
  console.log(`RLS Enabled Tables in schema: ${rlsEnabledCount}`);
  console.log(`Defined RLS Security Policies: ${policyCount}`);
} else {
  console.log('schema.sql not found in ./supabase/schema.sql');
}
console.log('\nAudit execution finished.');
