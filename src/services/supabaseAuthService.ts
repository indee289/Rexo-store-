import { supabase } from '../lib/supabaseClient';
import { logUserSession, logSecurityEvent } from './securityService';
import { UserProfile } from '../types';

export class SupabaseAuthService {
  /**
   * Sign up a new user with Supabase Auth
   */
  public async signUp(email: string, pass: string, name: string, role: 'creator' | 'brand' = 'creator') {
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password: pass,
        options: {
          data: {
            name,
            role,
          },
        },
      });

      if (error) throw error;

      if (data.user) {
        // Sync to public.users table
        const newUser: Partial<UserProfile> = {
          id: data.user.id,
          email: data.user.email || email,
          name,
          username: email.split('@')[0],
          role,
          avatar: `https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200`,
          isVerified: false,
          accountStatus: 'active',
        };

        await supabase.from('users').upsert({
          id: newUser.id,
          email: newUser.email,
          name: newUser.name,
          role: newUser.role,
          avatar: newUser.avatar,
        });

        return { user: data.user, profile: newUser, error: null };
      }

      return { user: null, profile: null, error: new Error('User creation failed') };
    } catch (err: any) {
      return { user: null, profile: null, error: err };
    }
  }

  /**
   * Sign in user with email & password
   */
  public async signIn(email: string, pass: string) {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password: pass,
      });

      if (error) throw error;
      return { session: data.session, user: data.user, error: null };
    } catch (err: any) {
      return { session: null, user: null, error: err };
    }
  }

  /**
   * Sign out current user
   */
  public async signOut() {
    try {
      await supabase.auth.signOut();
      return { error: null };
    } catch (err: any) {
      return { error: err };
    }
  }

  /**
   * Fetch user profile from public.users table
   */
  public async getUserProfile(userId: string) {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .single();
        
      if (error || !data) return null;
      
      const { data: { user } } = await supabase.auth.getUser();
      const meta = user?.user_metadata || {};
      
      // Map DB fields and Metadata to Frontend fields
      const profile = { ...data, ...meta };
      if (profile.social_links) {
        profile.socialLinks = profile.social_links;
      }
      if (profile.avatar_url && !profile.avatar) {
        profile.avatar = profile.avatar_url;
      }
      
      return profile;
    } catch {
      return null;
    }
  }
}

export const supabaseAuthService = new SupabaseAuthService();
