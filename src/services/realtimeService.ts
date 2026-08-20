import { supabase } from '../lib/supabaseClient';

export class RealtimeService {
  /**
   * Subscribe to Supabase table changes
   */
  public subscribeToTable(
    table: string,
    callback: (payload: any) => void
  ) {
    const channel = supabase
      .channel(`public:${table}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table },
        (payload) => {
          callback(payload);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }

  /**
   * Subscribe to user-specific notifications
   */
  public subscribeUserNotifications(userId: string, onNewNotif: (notif: any) => void) {
    const channel = supabase
      .channel(`user_notifications:${userId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'notifications',
          filter: `user_id=eq.${userId}`,
        },
        (payload) => {
          onNewNotif(payload.new);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }
}

export const realtimeService = new RealtimeService();
