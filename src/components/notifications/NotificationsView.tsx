import React from 'react';
import { NotificationCenterView } from './NotificationCenterView';

export const NotificationsView: React.FC<{
  onNavigateToScreen?: (screen: string, targetId?: string) => void;
}> = (props) => {
  return <NotificationCenterView onNavigateToScreen={props.onNavigateToScreen} />;
};
