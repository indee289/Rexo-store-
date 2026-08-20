export interface ModerationQueueItem {
  id: string;
  target_type: 'user' | 'campaign' | 'product' | 'message' | 'review' | 'withdrawal';
  target_id: string;
  reporter_id?: string;
  ai_risk_score?: number;
  ai_confidence?: number;
  ai_category?: string;
  ai_reason?: string;
  recommended_action?: string;
  status: 'pending' | 'reviewed_approved' | 'reviewed_rejected' | 'action_taken';
  admin_id?: string;
  admin_notes?: string;
  created_at: string;
  resolved_at?: string;
}

export interface SecurityAuditLog {
  id: string;
  action: string;
  actor_id: string;
  target_id: string;
  ip_hash?: string;
  details: Record<string, any>;
  created_at: string;
}

export interface DeviceFingerprint {
  device_hash: string;
  first_seen: string;
  last_seen: string;
  device_type: string;
  platform: string;
  app_version: string;
  risk_score: number;
  is_blacklisted: boolean;
}

export interface UserWarning {
  id: string;
  user_id: string;
  admin_id: string;
  reason: string;
  evidence?: string;
  issued_at: string;
}
