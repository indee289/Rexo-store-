# API Function Updates - Phase 1 Critical Fixes

## Overview

This document details all API function changes implemented in Phase 1 critical fixes, including new function endpoints, updated calling patterns, and integration examples for application developers.

## Summary of API Changes

| Function Name | Type | Description | Availability |
|---------------|------|-------------|-------------|
| `credit_wallet` | New Alias | Wrapper for `increment_wallet_balance` | ✅ Available |
| `debit_wallet` | New Alias | Wrapper for `decrement_wallet_balance` | ✅ Available |
| `increment_wallet_balance` | Preserved | Original wallet credit function | ✅ Unchanged |
| `decrement_wallet_balance` | Preserved | Original wallet debit function | ✅ Unchanged |

## New Function Endpoints

### 1. credit_wallet Function

#### Function Signature
```sql
credit_wallet(
    target_user_id UUID,
    amount DECIMAL(10,2)
) RETURNS TABLE(
    success BOOLEAN,
    new_balance DECIMAL,
    message TEXT
)
```

#### Description
Adds funds to a user's wallet balance. This is an alias function that wraps `increment_wallet_balance` for backward compatibility with admin applications.

#### Parameters
- `target_user_id` (UUID, required): The UUID of the user whose wallet will be credited
- `amount` (DECIMAL(10,2), required): The amount to add to the wallet (must be positive)

#### Return Values
| Field | Type | Description |
|-------|------|-------------|
| `success` | BOOLEAN | `true` if operation succeeded, `false` if failed |
| `new_balance` | DECIMAL | The wallet balance after the operation |
| `message` | TEXT | Success confirmation or error message |

#### Usage Examples

**JavaScript/TypeScript (Supabase Client)**
```javascript
// Credit user wallet with $50.00
const { data, error } = await supabase.rpc('credit_wallet', {
    target_user_id: '123e4567-e89b-12d3-a456-426614174000',
    amount: 50.00
});

if (error) {
    console.error('Wallet credit failed:', error.message);
    return;
}

const result = data[0];
if (result.success) {
    console.log(`Wallet credited successfully. New balance: $${result.new_balance}`);
    console.log(`Message: ${result.message}`);
} else {
    console.error(`Credit failed: ${result.message}`);
}
```

**Dart/Flutter (Supabase Dart Client)**
```dart
// Credit user wallet - Admin deposit approval
Future<Map<String, dynamic>?> creditUserWallet({
  required String userId,
  required double amount,
}) async {
  try {
    final response = await supabase.rpc('credit_wallet', params: {
      'target_user_id': userId,
      'amount': amount,
    });

    if (response is List && response.isNotEmpty) {
      final result = response.first as Map<String, dynamic>;
      
      if (result['success'] == true) {
        print('Wallet credited: \${result['new_balance']}');
        return result;
      } else {
        print('Credit failed: \${result['message']}');
        return null;
      }
    }
  } catch (e) {
    print('Error crediting wallet: \$e');
    return null;
  }
  return null;
}

// Usage in admin deposit approval
await creditUserWallet(
  userId: depositRequest.userId,
  amount: depositRequest.amount,
);
```

**SQL Direct Call**
```sql
-- Direct SQL call (for database scripts)
SELECT * FROM credit_wallet(
    '123e4567-e89b-12d3-a456-426614174000'::UUID,
    50.00::DECIMAL
);
```

#### Error Handling
```javascript
// Comprehensive error handling example
const creditWallet = async (userId, amount) => {
    try {
        const { data, error } = await supabase.rpc('credit_wallet', {
            target_user_id: userId,
            amount: amount
        });

        // Handle Supabase RPC errors
        if (error) {
            throw new Error(`RPC Error: ${error.message}`);
        }

        // Handle function-level errors
        const result = data[0];
        if (!result.success) {
            throw new Error(`Wallet Error: ${result.message}`);
        }

        return {
            success: true,
            newBalance: result.new_balance,
            message: result.message
        };

    } catch (error) {
        console.error('Credit wallet operation failed:', error);
        return {
            success: false,
            error: error.message
        };
    }
};
```

### 2. debit_wallet Function

#### Function Signature
```sql
debit_wallet(
    target_user_id UUID,
    amount DECIMAL(10,2)
) RETURNS TABLE(
    success BOOLEAN,
    new_balance DECIMAL,
    message TEXT
)
```

#### Description
Removes funds from a user's wallet balance with balance validation. This is an alias function that wraps `decrement_wallet_balance` for backward compatibility with admin applications.

#### Parameters
- `target_user_id` (UUID, required): The UUID of the user whose wallet will be debited
- `amount` (DECIMAL(10,2), required): The amount to remove from the wallet (must be positive)

#### Return Values
| Field | Type | Description |
|-------|------|-------------|
| `success` | BOOLEAN | `true` if operation succeeded, `false` if insufficient funds or error |
| `new_balance` | DECIMAL | The wallet balance after the operation (0 if failed) |
| `message` | TEXT | Success confirmation or error message (e.g., "Insufficient funds") |

#### Usage Examples

**JavaScript/TypeScript (Supabase Client)**
```javascript
// Debit user wallet for $25.00 withdrawal
const { data, error } = await supabase.rpc('debit_wallet', {
    target_user_id: '123e4567-e89b-12d3-a456-426614174000',
    amount: 25.00
});

if (error) {
    console.error('Wallet debit failed:', error.message);
    return;
}

const result = data[0];
if (result.success) {
    console.log(`Wallet debited successfully. New balance: $${result.new_balance}`);
} else {
    console.error(`Debit failed: ${result.message}`);
    // Handle insufficient funds case
    if (result.message.includes('Insufficient funds')) {
        showInsufficientFundsDialog();
    }
}
```

**Dart/Flutter (Supabase Dart Client)**
```dart
// Debit user wallet - Admin withdrawal approval
Future<Map<String, dynamic>?> debitUserWallet({
  required String userId,
  required double amount,
}) async {
  try {
    final response = await supabase.rpc('debit_wallet', params: {
      'target_user_id': userId,
      'amount': amount,
    });

    if (response is List && response.isNotEmpty) {
      final result = response.first as Map<String, dynamic>;
      
      if (result['success'] == true) {
        print('Wallet debited: \${result['new_balance']}');
        return result;
      } else {
        print('Debit failed: \${result['message']}');
        
        // Handle specific error cases
        if (result['message'].toString().contains('Insufficient funds')) {
          // Show insufficient funds error to admin
          showError('User has insufficient funds for this withdrawal');
        }
        return null;
      }
    }
  } catch (e) {
    print('Error debiting wallet: \$e');
    return null;
  }
  return null;
}

// Usage in admin withdrawal approval
final result = await debitUserWallet(
  userId: withdrawalRequest.userId,
  amount: withdrawalRequest.amount,
);

if (result != null) {
  // Update withdrawal request status to approved
  await updateWithdrawalStatus(withdrawalRequest.id, 'approved');
}
```

**SQL Direct Call**
```sql
-- Direct SQL call with balance check
SELECT * FROM debit_wallet(
    '123e4567-e89b-12d3-a456-426614174000'::UUID,
    25.00::DECIMAL
);
```

## Preserved Functions (No Changes)

### increment_wallet_balance & decrement_wallet_balance

These original functions remain **completely unchanged** and continue to work exactly as before. The new alias functions simply call these underlying implementations.

#### Original Function Signatures (Unchanged)
```sql
-- Original functions - no modifications
increment_wallet_balance(target_user_id UUID, amount DECIMAL) 
RETURNS TABLE(success BOOLEAN, new_balance DECIMAL, message TEXT)

decrement_wallet_balance(target_user_id UUID, amount DECIMAL) 
RETURNS TABLE(success BOOLEAN, new_balance DECIMAL, message TEXT)
```

#### Backward Compatibility
```javascript
// These calls continue to work exactly as before
const { data, error } = await supabase.rpc('increment_wallet_balance', {
    target_user_id: userId,
    amount: 50.00
});

const { data, error } = await supabase.rpc('decrement_wallet_balance', {
    target_user_id: userId,
    amount: 25.00
});
```

## Integration Patterns

### Admin Panel Integration

#### Deposit Approval Workflow
```javascript
// Admin approves user deposit
class AdminDepositService {
    async approveDeposit(depositId, adminId) {
        try {
            // 1. Get deposit details
            const { data: deposit } = await supabase
                .from('deposits')
                .select('*')
                .eq('id', depositId)
                .single();

            if (!deposit || deposit.status !== 'pending') {
                throw new Error('Invalid deposit request');
            }

            // 2. Credit user wallet using new alias function
            const { data, error } = await supabase.rpc('credit_wallet', {
                target_user_id: deposit.user_id,
                amount: deposit.amount
            });

            if (error) throw error;

            const result = data[0];
            if (!result.success) {
                throw new Error(result.message);
            }

            // 3. Update deposit status
            await supabase
                .from('deposits')
                .update({
                    status: 'approved',
                    approved_by: adminId,
                    approved_at: new Date().toISOString(),
                    wallet_balance_after: result.new_balance
                })
                .eq('id', depositId);

            return {
                success: true,
                newBalance: result.new_balance
            };

        } catch (error) {
            console.error('Deposit approval failed:', error);
            throw error;
        }
    }
}
```

#### Withdrawal Approval Workflow
```javascript
// Admin approves user withdrawal
class AdminWithdrawalService {
    async approveWithdrawal(withdrawalId, adminId) {
        try {
            // 1. Get withdrawal details
            const { data: withdrawal } = await supabase
                .from('withdrawals')
                .select('*')
                .eq('id', withdrawalId)
                .single();

            if (!withdrawal || withdrawal.status !== 'pending') {
                throw new Error('Invalid withdrawal request');
            }

            // 2. Debit user wallet using new alias function
            const { data, error } = await supabase.rpc('debit_wallet', {
                target_user_id: withdrawal.user_id,
                amount: withdrawal.amount
            });

            if (error) throw error;

            const result = data[0];
            if (!result.success) {
                // Handle insufficient funds
                if (result.message.includes('Insufficient funds')) {
                    await supabase
                        .from('withdrawals')
                        .update({
                            status: 'rejected',
                            rejected_reason: 'Insufficient wallet balance',
                            reviewed_by: adminId,
                            reviewed_at: new Date().toISOString()
                        })
                        .eq('id', withdrawalId);
                    
                    throw new Error('Insufficient wallet balance for withdrawal');
                }
                throw new Error(result.message);
            }

            // 3. Update withdrawal status and process payout
            await supabase
                .from('withdrawals')
                .update({
                    status: 'approved',
                    approved_by: adminId,
                    approved_at: new Date().toISOString(),
                    wallet_balance_after: result.new_balance
                })
                .eq('id', withdrawalId);

            // 4. Trigger external payout process
            await this.processPayout(withdrawal);

            return {
                success: true,
                newBalance: result.new_balance
            };

        } catch (error) {
            console.error('Withdrawal approval failed:', error);
            throw error;
        }
    }
}
```

### Flutter Admin App Integration

#### Admin Provider Service
```dart
// lib/services/admin_provider.dart
class AdminProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Credit user wallet (deposit approval)
  Future<bool> approveDeposit({
    required String depositId,
    required String userId,
    required double amount,
  }) async {
    try {
      // Use new credit_wallet function
      final response = await _supabase.rpc('credit_wallet', params: {
        'target_user_id': userId,
        'amount': amount,
      });

      if (response is List && response.isNotEmpty) {
        final result = response.first as Map<String, dynamic>;
        
        if (result['success'] == true) {
          // Update deposit record
          await _supabase.from('deposits').update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
            'wallet_balance_after': result['new_balance'],
          }).eq('id', depositId);

          notifyListeners();
          return true;
        } else {
          print('Credit failed: ${result['message']}');
          return false;
        }
      }
    } catch (e) {
      print('Error approving deposit: $e');
      return false;
    }
    return false;
  }

  // Debit user wallet (withdrawal approval)
  Future<bool> approveWithdrawal({
    required String withdrawalId,
    required String userId,
    required double amount,
  }) async {
    try {
      // Use new debit_wallet function
      final response = await _supabase.rpc('debit_wallet', params: {
        'target_user_id': userId,
        'amount': amount,
      });

      if (response is List && response.isNotEmpty) {
        final result = response.first as Map<String, dynamic>;
        
        if (result['success'] == true) {
          // Update withdrawal record
          await _supabase.from('withdrawals').update({
            'status': 'approved',
            'approved_at': DateTime.now().toIso8601String(),
            'wallet_balance_after': result['new_balance'],
          }).eq('id', withdrawalId);

          notifyListeners();
          return true;
        } else {
          // Handle insufficient funds or other errors
          if (result['message'].toString().contains('Insufficient funds')) {
            await _supabase.from('withdrawals').update({
              'status': 'rejected',
              'rejected_reason': 'Insufficient wallet balance',
              'reviewed_at': DateTime.now().toIso8601String(),
            }).eq('id', withdrawalId);
          }
          
          print('Debit failed: ${result['message']}');
          return false;
        }
      }
    } catch (e) {
      print('Error approving withdrawal: $e');
      return false;
    }
    return false;
  }
}
```

## Security and Permissions

### Function Access Control

Both new alias functions inherit the same security restrictions as their underlying implementations:

```sql
-- Admin-only access (same as original functions)
GRANT EXECUTE ON FUNCTION credit_wallet TO admin_role;
GRANT EXECUTE ON FUNCTION debit_wallet TO admin_role;

-- No public access
REVOKE ALL ON FUNCTION credit_wallet FROM PUBLIC;
REVOKE ALL ON FUNCTION debit_wallet FROM PUBLIC;
```

### Row Level Security Integration

The functions work seamlessly with existing RLS policies:

```sql
-- Admin access verification within functions
-- Functions check admin role before executing operations
-- All existing security policies remain active and enforced
```

### Authentication Requirements

```javascript
// Authentication must be established before calling functions
const { data: { session } } = await supabase.auth.getSession();

if (!session) {
    throw new Error('Authentication required');
}

// Check admin role
const userRole = session.user.app_metadata?.role;
if (userRole !== 'admin') {
    throw new Error('Admin access required');
}

// Now safe to call admin functions
const result = await supabase.rpc('credit_wallet', params);
```

## Testing and Validation

### Unit Testing Examples

```javascript
// Jest test examples for new functions
describe('Wallet API Functions', () => {
    
    test('credit_wallet should add funds to user wallet', async () => {
        const { data, error } = await supabase.rpc('credit_wallet', {
            target_user_id: testUserId,
            amount: 50.00
        });

        expect(error).toBeNull();
        expect(data[0].success).toBe(true);
        expect(parseFloat(data[0].new_balance)).toBeGreaterThan(0);
    });

    test('debit_wallet should remove funds with balance check', async () => {
        // First ensure sufficient balance
        await supabase.rpc('credit_wallet', {
            target_user_id: testUserId,
            amount: 100.00
        });

        // Then test debit
        const { data, error } = await supabase.rpc('debit_wallet', {
            target_user_id: testUserId,
            amount: 30.00
        });

        expect(error).toBeNull();
        expect(data[0].success).toBe(true);
    });

    test('debit_wallet should fail with insufficient funds', async () => {
        const { data, error } = await supabase.rpc('debit_wallet', {
            target_user_id: testUserId,
            amount: 999999.00  // Impossibly large amount
        });

        expect(error).toBeNull();
        expect(data[0].success).toBe(false);
        expect(data[0].message).toContain('Insufficient funds');
    });
});
```

### Integration Testing

```javascript
// Full workflow integration test
describe('Admin Approval Workflow', () => {
    test('complete deposit approval workflow', async () => {
        // 1. Create test deposit request
        const deposit = await createTestDeposit(testUserId, 75.00);

        // 2. Admin approves using new function
        const result = await adminService.approveDeposit(deposit.id, adminId);

        // 3. Verify wallet balance updated
        const wallet = await getUserWallet(testUserId);
        expect(wallet.balance).toBe(75.00);

        // 4. Verify deposit status updated
        const updatedDeposit = await getDeposit(deposit.id);
        expect(updatedDeposit.status).toBe('approved');
    });
});
```

## Migration Guide

### For Existing Applications

**No changes required** for applications currently using `increment_wallet_balance` and `decrement_wallet_balance`. These functions remain fully functional.

### For New Admin Applications

Use the new alias functions for better naming consistency:

```javascript
// ❌ Old approach (still works but less intuitive naming)
await supabase.rpc('increment_wallet_balance', params);

// ✅ New approach (recommended for admin applications)
await supabase.rpc('credit_wallet', params);
```

### Function Migration Timeline

- **Phase 1** (Current): Both old and new functions available
- **Phase 2** (Future): Continue supporting both for backward compatibility
- **Long-term**: New applications should use the alias functions for consistency

## Performance Considerations

### Function Call Overhead
- **Alias functions**: Single wrapper call - negligible performance impact (< 1ms)
- **Original functions**: No performance change - continue optimized execution
- **Database connections**: No additional connection overhead

### Query Optimization
```sql
-- Functions use optimized database queries
-- Proper indexing on wallet-related tables
-- Transactional safety for all operations
```

## Troubleshooting

### Common Issues

**Issue**: "Function credit_wallet does not exist"
```bash
# Solution: Verify migration was applied
psql $DATABASE_URL -c "SELECT proname FROM pg_proc WHERE proname = 'credit_wallet';"
```

**Issue**: "Permission denied for function credit_wallet"
```bash
# Solution: Verify admin role is assigned
psql $DATABASE_URL -c "SELECT auth.jwt() ->> 'role';"
```

**Issue**: Function call returns empty result
```javascript
// Check for proper array access
const result = data[0];  // Functions return array of results
if (result && result.success) {
    // Process success case
}
```

---

**Document Version**: 1.0  
**Last Updated**: January 2024  
**API Version**: Phase 1 Complete