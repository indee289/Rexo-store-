import { supabase } from '../lib/supabaseClient';

export class SupabaseDataService {
  // ==================== CAMPAIGNS ====================
  public async fetchCampaigns() {
    try {
      const { data, error } = await supabase
        .from('campaigns')
        .select('*')
        .order('createdAt', { ascending: false });
      if (error || !data) return [];
      return data;
    } catch {
      return [];
    }
  }
  public async createCampaign(campaignData: any) {
    try {
      const { data, error } = await supabase
        .from('campaigns')
        .insert(campaignData)
        .select()
        .single();
      if (error) throw error;
      return data;
    } catch (err: any) {
      console.warn('[Supabase] Create campaign fallback:', err.message);
      return campaignData;
    }
  }
  // ==================== DEPOSITS ====================
  public async createDepositRequest(depositData: any) {
    try {
      const { data, error } = await supabase
        .from('deposits')
        .insert(depositData)
        .select()
        .single();
      if (error) throw error;
      return data;
    } catch (err: any) {
      return depositData;
    }
  }
  public async updateDepositStatus(id: string, status: 'approved' | 'rejected', notes?: string) {
    try {
      const { data, error } = await supabase
        .from('deposits')
        .update({ status, admin_notes: notes, processed_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data;
    } catch (err: any) {
      return null;
    }
  }
  // ==================== WITHDRAWALS ====================
  public async createWithdrawalRequest(withdrawalData: any) {
    try {
      const { data, error } = await supabase
        .from('withdrawals')
        .insert(withdrawalData)
        .select()
        .single();
      if (error) throw error;
      return data;
    } catch (err: any) {
      return withdrawalData;
    }
  }
  public async updateWithdrawalStatus(id: string, status: 'approved' | 'rejected', ref?: string) {
    try {
      const { data, error } = await supabase
        .from('withdrawals')
        .update({ status, transaction_ref: ref, processed_at: new Date().toISOString() })
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data;
    } catch {
      return null;
    }
  }
  // ==================== NOTIFICATIONS ====================
  public async fetchNotifications(userId: string) {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .select('*')
        .or(`user_id.eq.\${userId},user_id.eq.all`)
        .order('createdAt', { ascending: false });
      if (error || !data) return [];
      return data;
    } catch {
      return [];
    }
  }
  public async createNotification(notifData: any) {
    try {
      const { data, error } = await supabase
        .from('notifications')
        .insert(notifData)
        .select()
        .single();
      if (error) throw error;
      return data;
    } catch {
      return notifData;
    }
  }
  // ==================== AUDIT LOGS ====================
  public async logAuditAction(logData: any) {
    try {
      await supabase.from('audit_logs').insert(logData);
    } catch (err: any) {
      console.warn('[Audit Log] Local logging fallback:', err.message);
    }
  }

  // ==================== PROFILE ====================
  
  public async createProduct(productData: any) {
    try {
      const { data, error } = await supabase
        .from('products')
        .insert(productData)
        .select()
        .single();
      if (error) throw error;
      return data;
    } catch (err: any) {
      console.warn('[Supabase] Create product fallback:', err.message);
      return productData;
    }
  }

  public async fetchProducts() {
    try {
      const { data, error } = await supabase
        .from('products')
        .select('*');
      if (error || !data) return [];
      return data;
    } catch {
      return [];
    }
  }

  public async updateUserProfile(userId: string, updates: any) {
    try {
      const dbUpdates: any = { ...updates };
      if (updates.socialLinks !== undefined) {
        dbUpdates.social_links = updates.socialLinks;
        delete dbUpdates.socialLinks;
      }
      
      // 1. Try to update 'users' table with fields that might exist (name, avatar_url)
      const tableUpdates: any = {};
      if (dbUpdates.name) tableUpdates.name = dbUpdates.name;
      if (dbUpdates.avatar) tableUpdates.avatar_url = dbUpdates.avatar;
      
      if (Object.keys(tableUpdates).length > 0) {
        await supabase.from('users').update(tableUpdates).eq('id', userId);
      }
      
      // 2. Always store everything in auth.users user_metadata as fallback/source of truth for extra fields
      const { data: authData, error: authError } = await supabase.auth.updateUser({
        data: dbUpdates
      });
      
      if (authError) {
        console.error('Error updating auth metadata:', authError);
      }
         
      return { ...tableUpdates, ...dbUpdates };
    } catch (err: any) {
      console.warn('Profile update error:', err);
      return null;
    }
  }


  // Generic update/delete
  public async updateRecord(table: string, id: string, updates: any) {
    try {
      const { error } = await supabase.from(table).update(updates).eq('id', id);
      if (error) console.error(`Failed to update ${table}:`, error);
    } catch (err) {
      console.error(`[Supabase] Error updating ${table}`, err);
    }
  }

  public async deleteRecord(table: string, id: string) {
    try {
      const { error } = await supabase.from(table).delete().eq('id', id);
      if (error) console.error(`Failed to delete ${table}:`, error);
    } catch (err) {
      console.error(`[Supabase] Error deleting ${table}`, err);
    }
  }
}
export const supabaseDataService = new SupabaseDataService();
