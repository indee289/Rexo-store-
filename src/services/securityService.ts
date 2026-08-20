import { supabase } from '../lib/supabaseClient';

export interface UserSession {
  id: string;
  device_info: string;
  ip_address: string;
  last_active: string;
  is_current: boolean;
  status: string;
}

export interface SecurityLog {
  id: string;
  action: string;
  ip_address: string;
  device_info: string;
  status: string;
  created_at: string;
}

export const fetchActiveSessions = async (): Promise<UserSession[]> => {
  const { data, error } = await supabase
    .from('user_sessions')
    .select('*')
    .order('last_active', { ascending: false });
    
  if (error) {
    console.error('Error fetching sessions:', error);
    return [];
  }
  return data as UserSession[];
};

export const fetchSecurityLogs = async (): Promise<SecurityLog[]> => {
  const { data, error } = await supabase
    .from('security_logs')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(20);
    
  if (error) {
    console.error('Error fetching security logs:', error);
    return [];
  }
  return data as SecurityLog[];
};

export const revokeSession = async (sessionId: string): Promise<boolean> => {
  const { error } = await supabase
    .from('user_sessions')
    .update({ status: 'revoked' })
    .eq('id', sessionId);
    
  if (error) {
    console.error('Error revoking session:', error);
    return false;
  }
  return true;
};

export const logUserSession = async (userId: string) => {
  const userAgent = navigator.userAgent;
  let deviceType = 'Unknown Device';
  if (/android/i.test(userAgent)) deviceType = 'Android Mobile';
  else if (/iPad|iPhone|iPod/.test(userAgent)) deviceType = 'iOS Device';
  else if (/Windows/.test(userAgent)) deviceType = 'Windows PC';
  else if (/Mac OS/.test(userAgent)) deviceType = 'Mac OS';
  else if (/Linux/.test(userAgent)) deviceType = 'Linux PC';
  
  // Real IP would normally be captured by an Edge function or server, using dummy IP for frontend for now
  const mockIp = '103.21.' + Math.floor(Math.random() * 255) + '.' + Math.floor(Math.random() * 255);

  const { error } = await supabase.from('user_sessions').upsert({
     user_id: userId,
     device_info: deviceType,
     ip_address: mockIp,
     last_active: new Date().toISOString(),
     is_current: true,
     status: 'active'
  }, { onConflict: 'user_id, device_info' });
  
  if (error) console.error('Error logging session', error);
};

export const logSecurityEvent = async (userId: string, action: string, status: string = 'success') => {
  const { error } = await supabase.from('security_logs').insert({
    user_id: userId,
    action: action,
    status: status,
    ip_address: '103.21.124.8', // Mock IP
    device_info: navigator.userAgent
  });
};
