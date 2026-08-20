import { AppNotification } from '../types';

export interface DeepLinkHandler {
  navigateToCampaign: (campaignId: string) => void;
  navigateToWallet: () => void;
  navigateToWithdrawalDetails: (withdrawalId?: string) => void;
  navigateToAdminMessage: (notificationId: string) => void;
  navigateToKycStatus: () => void;
  navigateToProfile: () => void;
}

class DeepLinkService {
  private handler: DeepLinkHandler | null = null;

  public registerHandler(handler: DeepLinkHandler) {
    this.handler = handler;
  }

  public unregisterHandler() {
    this.handler = null;
  }

  public handleNotificationClick(notification: AppNotification) {
    if (!this.handler) {
      console.warn('[DeepLinkService] No deep link handler registered yet.');
      return;
    }

    const { screen, targetId } = notification.payload || {};

    switch (screen || this.mapTypeToScreen(notification.type)) {
      case 'CampaignDetails':
        if (targetId) {
          this.handler.navigateToCampaign(targetId);
        } else {
          this.handler.navigateToCampaign('all');
        }
        break;

      case 'Wallet':
        this.handler.navigateToWallet();
        break;

      case 'WithdrawalDetails':
        this.handler.navigateToWithdrawalDetails(targetId);
        break;

      case 'AdminMessage':
        this.handler.navigateToAdminMessage(notification.id);
        break;

      case 'KYCStatus':
        this.handler.navigateToKycStatus();
        break;

      case 'Profile':
        this.handler.navigateToProfile();
        break;

      default:
        // Fallback route mapping based on type
        if (notification.type.includes('campaign')) {
          this.handler.navigateToCampaign(targetId || 'all');
        } else if (notification.type.includes('withdrawal') || notification.type.includes('wallet') || notification.type.includes('deposit')) {
          this.handler.navigateToWallet();
        } else if (notification.type.includes('kyc') || notification.type.includes('user_verified')) {
          this.handler.navigateToKycStatus();
        } else {
          this.handler.navigateToAdminMessage(notification.id);
        }
        break;
    }
  }

  private mapTypeToScreen(type: string): string {
    if (type.startsWith('campaign') || type.includes('creator')) return 'CampaignDetails';
    if (type.startsWith('withdrawal')) return 'WithdrawalDetails';
    if (type.startsWith('wallet') || type.startsWith('deposit')) return 'Wallet';
    if (type.startsWith('kyc') || type === 'user_verified') return 'KYCStatus';
    return 'AdminMessage';
  }
}

export const deepLinkService = new DeepLinkService();
