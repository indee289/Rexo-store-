package com.rexo.marketplace.data.local

import androidx.room.*
import com.rexo.marketplace.data.model.*
import kotlinx.coroutines.flow.Flow

/**
 * Wallet Data Access Object
 */
@Dao
interface WalletDao {
    
    // Wallet
    @Query("SELECT * FROM wallets WHERE userId = :userId")
    fun getWalletFlow(userId: String): Flow<Wallet?>
    
    @Query("SELECT * FROM wallets WHERE userId = :userId")
    suspend fun getWallet(userId: String): Wallet?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertWallet(wallet: Wallet)
    
    @Update
    suspend fun updateWallet(wallet: Wallet)
    
    // Transactions
    @Query("SELECT * FROM wallet_transactions WHERE userId = :userId ORDER BY createdAt DESC")
    fun getTransactionsFlow(userId: String): Flow<List<WalletTransaction>>
    
    @Query("SELECT * FROM wallet_transactions WHERE userId = :userId ORDER BY createdAt DESC LIMIT :limit")
    suspend fun getRecentTransactions(userId: String, limit: Int = 20): List<WalletTransaction>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTransaction(transaction: WalletTransaction)
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTransactions(transactions: List<WalletTransaction>)
    
    // Withdrawals
    @Query("SELECT * FROM withdrawal_requests WHERE userId = :userId ORDER BY createdAt DESC")
    fun getWithdrawalRequestsFlow(userId: String): Flow<List<WithdrawalRequest>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertWithdrawalRequest(request: WithdrawalRequest)
    
    // Deposits
    @Query("SELECT * FROM deposit_requests WHERE brandId = :brandId ORDER BY createdAt DESC")
    fun getDepositRequestsFlow(brandId: String): Flow<List<DepositRequest>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertDepositRequest(request: DepositRequest)
    
    @Query("DELETE FROM wallet_transactions")
    suspend fun deleteAllTransactions()
}
