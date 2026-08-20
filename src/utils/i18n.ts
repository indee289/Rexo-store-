export type SupportedLanguage = 'English' | 'Hindi (हिंदी)' | 'Hinglish' | 'Spanish (Español)';

export interface Translations {
  profileTitle: string;
  memberSince: string;
  moneyEarned: string;
  totalVideos: string;
  totalViews: string;
  connectedAccounts: string;
  linkedCount: string;
  referrals: string;
  earnPercent: string;
  language: string;
  theme: string;
  notifications: string;
  faq: string;
  resources: string;
  support: string;
  privacyPolicy: string;
  switchWorkspace: string;
  security: string;
  logout: string;
  save: string;
  copied: string;
  shareReferral: string;
  supportSubmitted: string;
}

const translations: Record<string, Translations> = {
  English: {
    profileTitle: 'Profile',
    memberSince: 'Member since',
    moneyEarned: 'Money earned',
    totalVideos: 'Total videos',
    totalViews: 'Total views',
    connectedAccounts: 'Connected accounts',
    linkedCount: 'Linked',
    referrals: 'Referrals',
    earnPercent: 'Earn 10%',
    language: 'Language',
    theme: 'Theme',
    notifications: 'Notifications',
    faq: 'FAQ',
    resources: 'Resources',
    support: 'Support',
    privacyPolicy: 'Privacy Policy',
    switchWorkspace: 'Switch Workspace / Role',
    security: 'Security',
    logout: 'Logout',
    save: 'Save Profile',
    copied: 'Referral link copied!',
    shareReferral: 'Share Referral Link',
    supportSubmitted: 'Support request submitted!',
  },
  'Hindi (हिंदी)': {
    profileTitle: 'प्रोफ़ाइल',
    memberSince: 'सदस्यता तिथि',
    moneyEarned: 'कुल कमाई',
    totalVideos: 'कुल वीडियो',
    totalViews: 'कुल व्यूज',
    connectedAccounts: 'जुड़े हुए खाते',
    linkedCount: 'लिंक किए गए',
    referrals: 'रेफरल प्रोग्राम',
    earnPercent: '10% कमाएं',
    language: 'भाषा',
    theme: 'थीम',
    notifications: 'सूचनाएं',
    faq: 'अक्सर पूछे जाने वाले प्रश्न',
    resources: 'संसाधन व गाइड',
    support: 'सहायता केंद्र',
    privacyPolicy: 'गोपनीयता नीति (Privacy Policy)',
    switchWorkspace: 'रोल / वर्कस्पेस बदलें',
    security: 'सुरक्षा सेटिंग्स',
    logout: 'लॉग आउट',
    save: 'प्रोफ़ाइल सेव करें',
    copied: 'रेफरल लिंक कॉपी हो गया!',
    shareReferral: 'रेफरल लिंक शेयर करें',
    supportSubmitted: 'सहायता अनुरोध सबमिट हो गया!',
  },
  Hinglish: {
    profileTitle: 'Profile',
    memberSince: 'Member since',
    moneyEarned: 'Total Kamai',
    totalVideos: 'Total Videos',
    totalViews: 'Total Views',
    connectedAccounts: 'Connected Accounts',
    linkedCount: 'Linked Hain',
    referrals: 'Referral Program',
    earnPercent: 'Earn Karo 10%',
    language: 'Bhasha / Language',
    theme: 'App Theme',
    notifications: 'Notifications',
    faq: 'FAQ aur Madad',
    resources: 'Guides aur Resources',
    support: 'Customer Support',
    privacyPolicy: 'Privacy Policy',
    switchWorkspace: 'Role Switch Karo',
    security: 'Security',
    logout: 'Logout Karo',
    save: 'Profile Save Karo',
    copied: 'Referral link copy ho gaya!',
    shareReferral: 'Referral Link Share Karo',
    supportSubmitted: 'Support request submit ho gaya!',
  },
  'Spanish (Español)': {
    profileTitle: 'Perfil',
    memberSince: 'Miembro desde',
    moneyEarned: 'Dinero ganado',
    totalVideos: 'Vídeos totales',
    totalViews: 'Vistas totales',
    connectedAccounts: 'Cuentas vinculadas',
    linkedCount: 'Vinculado',
    referrals: 'Referencias',
    earnPercent: 'Gana 10%',
    language: 'Idioma',
    theme: 'Tema',
    notifications: 'Notificaciones',
    faq: 'Preguntas frecuentes',
    resources: 'Recursos',
    support: 'Soporte',
    privacyPolicy: 'Política de Privacidad',
    switchWorkspace: 'Cambiar rol',
    security: 'Seguridad',
    logout: 'Cerrar sesión',
    save: 'Guardar perfil',
    copied: '¡Enlace de referencia copiado!',
    shareReferral: 'Compartir enlace',
    supportSubmitted: '¡Solicitud de soporte enviada!',
  },
};

export function getTranslation(lang?: string): Translations {
  if (!lang) return translations.English;
  return translations[lang] || translations.English;
}
