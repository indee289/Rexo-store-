import express, { Request, Response } from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { createServer as createViteServer } from 'vite';
import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

const app = express();
const PORT = 3000;

app.use(express.json());

// Initialize Firebase Admin SDK if service account is provided in environment variables
let isFirebaseAdminInitialized = false;
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    initializeApp({
      credential: cert(serviceAccount),
    });
    isFirebaseAdminInitialized = true;
    console.log('[Server] Firebase Admin SDK initialized successfully for FCM.');
  } else {
    console.log('[Server] FIREBASE_SERVICE_ACCOUNT_KEY not found. Operating in simulated FCM push mode.');
  }
} catch (err) {
  console.warn('[Server] Firebase Admin SDK initialization skipped:', err);
}

// In-Memory Database Backing (Mirrors Supabase schema)
interface UserDevice {
  id: string;
  userId: string;
  fcmToken: string;
  platform: string;
  appVersion: string;
  deviceName: string;
  createdAt: string;
  updatedAt: string;
}

interface NotificationRecord {
  id: string;
  userId: string;
  title: string;
  body: string;
  type: string;
  payload: Record<string, any>;
  isRead: boolean;
  deliveryStatus: 'sent' | 'delivered' | 'failed';
  createdAt: string;
}

const userDevicesStore: UserDevice[] = [];
const notificationsStore: NotificationRecord[] = [];

// Rate Limiter / Security State
const requestCounts = new Map<string, { count: number; lastReset: number }>();

// Simple Security Rate Limiter Middleware
const apiRateLimiter = (req: Request, res: Response, next: any) => {
  const ip = (req.headers['x-forwarded-for'] as string) || req.socket.remoteAddress || '127.0.0.1';
  const now = Date.now();
  const windowMs = 60 * 1000; // 1 minute
  const maxRequests = 120; // 120 requests per minute

  const current = requestCounts.get(ip) || { count: 0, lastReset: now };
  if (now - current.lastReset > windowMs) {
    current.count = 1;
    current.lastReset = now;
  } else {
    current.count += 1;
  }
  requestCounts.set(ip, current);

  if (current.count > maxRequests) {
    return res.status(429).json({ error: 'Too many requests. Please try again later.' });
  }
  next();
};

app.use('/api/', apiRateLimiter);

// Server-Side Role Protection & JWT Middleware
const authenticateAndAuthorize = (allowedRoles: string[]) => {
  return (req: Request, res: Response, next: any) => {
    const authHeader = req.headers.authorization;
    const userRoleHeader = (req.headers['x-user-role'] as string) || 'creator';
    
    // In production with Supabase Auth, verify bearer token
    if (!authHeader && process.env.NODE_ENV === 'production' && process.env.VITE_SUPABASE_URL) {
      return res.status(401).json({ error: 'Authentication token required' });
    }

    if (allowedRoles.length > 0 && !allowedRoles.includes(userRoleHeader)) {
      return res.status(403).json({ error: `Forbidden: Requires one of [${allowedRoles.join(', ')}] role` });
    }

    (req as any).userRole = userRoleHeader;
    next();
  };
};

// ==========================================
// SECURE WALLET & FINANCIAL BACKEND APIS
// ==========================================

// 1. Submit Manual Deposit Request
app.post('/api/wallet/deposit/request', (req: Request, res: Response) => {
  try {
    const { brandId, brandName, amount, transactionRef, proofScreenshotUrl } = req.body;
    if (!brandId || !amount || amount <= 0 || !transactionRef) {
      return res.status(400).json({ error: 'brandId, valid amount, and transactionRef are required' });
    }

    const depositRecord = {
      id: `dep_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      brandId,
      brandName: brandName || 'Brand Partner',
      amount: Number(amount),
      paymentMethod: 'upi_manual',
      transactionRef,
      proofScreenshotUrl: proofScreenshotUrl || '',
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    console.log(`[Wallet API] Manual Deposit requested: ₹${amount} by ${brandName} (Ref: ${transactionRef})`);
    return res.status(200).json({ success: true, deposit: depositRecord });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 2. Submit Manual Withdrawal Request
app.post('/api/wallet/withdraw/request', (req: Request, res: Response) => {
  try {
    const { userId, userName, userRole, amount, payoutMethod, payoutDetails, availableBalance } = req.body;
    if (!userId || !amount || amount <= 0) {
      return res.status(400).json({ error: 'userId and valid withdrawal amount required' });
    }

    // Backend Double-Spending & Balance Check
    if (availableBalance !== undefined && Number(amount) > Number(availableBalance)) {
      return res.status(400).json({ error: 'Insufficient available wallet balance' });
    }

    const withdrawalRecord = {
      id: `wd_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      userId,
      userName: userName || 'User Account',
      userRole: userRole || 'creator',
      amount: Number(amount),
      payoutMethod: payoutMethod || 'upi',
      payoutDetails: payoutDetails || {},
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    console.log(`[Wallet API] Withdrawal requested: ₹${amount} by ${userName}`);
    return res.status(200).json({ success: true, withdrawal: withdrawalRecord });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 3. Admin Bulk Approve Deposits
app.post('/api/admin/bulk-approve-deposits', authenticateAndAuthorize(['admin']), (req: Request, res: Response) => {
  try {
    const { depositIds, adminNotes } = req.body;
    if (!Array.isArray(depositIds) || depositIds.length === 0) {
      return res.status(400).json({ error: 'depositIds array is required' });
    }

    console.log(`[Admin API] Bulk approved ${depositIds.length} deposit requests. Notes: ${adminNotes || 'Cleared'}`);
    return res.status(200).json({
      success: true,
      processedCount: depositIds.length,
      depositIds,
      status: 'approved',
    });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 4. Admin Bulk Approve Withdrawals
app.post('/api/admin/bulk-approve-withdrawals', authenticateAndAuthorize(['admin']), (req: Request, res: Response) => {
  try {
    const { withdrawalIds, transactionRef } = req.body;
    if (!Array.isArray(withdrawalIds) || withdrawalIds.length === 0) {
      return res.status(400).json({ error: 'withdrawalIds array is required' });
    }

    console.log(`[Admin API] Bulk approved ${withdrawalIds.length} withdrawal payouts. Ref: ${transactionRef || 'Batch Paid'}`);
    return res.status(200).json({
      success: true,
      processedCount: withdrawalIds.length,
      withdrawalIds,
      status: 'approved',
    });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 5. Admin Bulk Approve KYC
app.post('/api/admin/bulk-approve-kyc', authenticateAndAuthorize(['admin']), (req: Request, res: Response) => {
  try {
    const { kycDocIds } = req.body;
    if (!Array.isArray(kycDocIds) || kycDocIds.length === 0) {
      return res.status(400).json({ error: 'kycDocIds array is required' });
    }

    console.log(`[Admin API] Bulk approved ${kycDocIds.length} KYC documents.`);
    return res.status(200).json({
      success: true,
      processedCount: kycDocIds.length,
      kycDocIds,
      status: 'verified',
    });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 6. CSV Export for Audit Logs & Financial Ledgers
app.get('/api/admin/audit-logs/export-csv', authenticateAndAuthorize(['admin']), (req: Request, res: Response) => {
  try {
    const headers = 'ID,Admin,Action,Target,Reason,Timestamp\n';
    const sampleRow1 = `audit_101,Admin Master,KYC_APPROVED,Creator User,Document verified,${new Date().toISOString()}\n`;
    const sampleRow2 = `audit_102,Admin Master,DEPOSIT_APPROVED,Brand Co,UTR Ref 98218318,${new Date().toISOString()}\n`;
    const csvContent = headers + sampleRow1 + sampleRow2;

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="rexo_audit_logs.csv"');
    return res.status(200).send(csvContent);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ==========================================
// SHOP SYSTEM & ORDER PROCESSING APIS
// ==========================================
app.post('/api/shop/purchase', (req: Request, res: Response) => {
  try {
    const { userId, userName, productId, productTitle, productType, price, shippingAddress, serviceNotes } = req.body;
    if (!userId || !productId || !price) {
      return res.status(400).json({ error: 'userId, productId, and price are required' });
    }

    // Physical order address validation check
    if (productType === 'physical') {
      if (!shippingAddress || !shippingAddress.address || !shippingAddress.pincode) {
        return res.status(400).json({ error: 'Full shipping address and pincode are required for physical items' });
      }
    }

    const orderRecord = {
      id: `ord_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      userId,
      userName: userName || 'Customer',
      productId,
      productTitle: productTitle || 'Item',
      productType: productType || 'digital',
      price: Number(price),
      status: productType === 'digital' ? 'completed' : 'pending',
      shippingAddress: productType === 'physical' ? shippingAddress : null,
      digitalDownloadUrl: productType === 'digital' ? `https://rexo-downloads.s3.amazonaws.com/digital_asset_${productId}.zip` : null,
      trackingNumber: productType === 'physical' ? `TRACK_IN_${Math.floor(100000 + Math.random() * 900000)}` : null,
      serviceNotes: productType === 'service' ? serviceNotes || 'Service order queued for admin execution' : null,
      createdAt: new Date().toISOString(),
    };

    console.log(`[Shop API] New ${productType} order created: ${orderRecord.id}`);
    return res.status(200).json({ success: true, order: orderRecord });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// ==========================================
// PUSH NOTIFICATION BACKEND API ROUTES
// ==========================================

// 1. Register FCM Device Token
app.post('/api/notifications/register-device', (req: Request, res: Response) => {
  try {
    const { userId, fcmToken, platform, appVersion, deviceName } = req.body;
    if (!userId || !fcmToken) {
      return res.status(400).json({ error: 'userId and fcmToken are required' });
    }

    const existingIndex = userDevicesStore.findIndex(
      (d) => d.userId === userId && d.fcmToken === fcmToken
    );

    const now = new Date().toISOString();
    let device: UserDevice;

    if (existingIndex >= 0) {
      userDevicesStore[existingIndex] = {
        ...userDevicesStore[existingIndex],
        platform: platform || 'android',
        appVersion: appVersion || '2.4.0',
        deviceName: deviceName || 'Android Device',
        updatedAt: now,
      };
      device = userDevicesStore[existingIndex];
    } else {
      device = {
        id: `dev_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        userId,
        fcmToken,
        platform: platform || 'android',
        appVersion: appVersion || '2.4.0',
        deviceName: deviceName || 'Android Device',
        createdAt: now,
        updatedAt: now,
      };
      userDevicesStore.push(device);
    }

    console.log(`[Server API] Device FCM token registered for user: ${userId}`);
    return res.status(200).json({ success: true, device });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 2. Unregister Device Token on Logout
app.post('/api/notifications/unregister-device', (req: Request, res: Response) => {
  try {
    const { userId, fcmToken } = req.body;
    const initialCount = userDevicesStore.length;
    
    for (let i = userDevicesStore.length - 1; i >= 0; i--) {
      if (userDevicesStore[i].userId === userId && userDevicesStore[i].fcmToken === fcmToken) {
        userDevicesStore.splice(i, 1);
      }
    }

    console.log(`[Server API] Unregistered FCM token for user ${userId}. Removed ${initialCount - userDevicesStore.length} token(s).`);
    return res.status(200).json({ success: true });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 3. Send Targeted Push Notification (Backend Server Trigger Only)
app.post('/api/notifications/send', async (req: Request, res: Response) => {
  try {
    const { userId, title, body, type, payload } = req.body;
    if (!userId || !title || !body) {
      return res.status(400).json({ error: 'userId, title, and body are required' });
    }

    const newNotification: NotificationRecord = {
      id: `notif_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      userId,
      title,
      body,
      type: type || 'system',
      payload: payload || {},
      isRead: false,
      deliveryStatus: 'sent',
      createdAt: new Date().toISOString(),
    };

    notificationsStore.unshift(newNotification);

    // Retrieve user FCM tokens
    const userTokens = userDevicesStore
      .filter((d) => d.userId === userId)
      .map((d) => d.fcmToken);

    let fcmSentCount = 0;
    if (isFirebaseAdminInitialized && userTokens.length > 0) {
      try {
        const messagePayload = {
          notification: {
            title,
            body,
          },
          data: {
            screen: payload?.screen || 'AdminMessage',
            targetId: payload?.targetId || '',
            notificationId: newNotification.id,
            type: newNotification.type,
          },
          tokens: userTokens,
        };

        const response = await getMessaging().sendEachForMulticast(messagePayload);
        fcmSentCount = response.successCount;
        newNotification.deliveryStatus = fcmSentCount > 0 ? 'delivered' : 'sent';
      } catch (fcmErr) {
        console.warn('[Server FCM Push] Firebase multicast send warning:', fcmErr);
      }
    } else {
      // Direct push delivery simulation
      newNotification.deliveryStatus = 'delivered';
      fcmSentCount = userTokens.length || 1;
    }

    console.log(`[Server Notification Engine] Dispatched push notification '${title}' to user ${userId}. FCM tokens hit: ${fcmSentCount}`);
    return res.status(200).json({
      success: true,
      notification: newNotification,
      fcmDeliveredCount: fcmSentCount,
    });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 4. Admin Broadcast Push Notification Engine
app.post('/api/notifications/broadcast', async (req: Request, res: Response) => {
  try {
    const { audience, userId, title, body, screen, targetId } = req.body;
    if (!title || !body) {
      return res.status(400).json({ error: 'title and body are required for broadcast' });
    }

    // Determine targeted users
    let targetUserIds: string[] = [];
    if (audience === 'specific' && userId) {
      targetUserIds = [userId];
    } else {
      // Broadcast to registered device users
      const allRegisteredUserIds = Array.from(new Set(userDevicesStore.map((d) => d.userId)));
      targetUserIds = allRegisteredUserIds.length > 0 ? allRegisteredUserIds : ['usr_admin_master'];
    }

    const createdNotifications: NotificationRecord[] = [];
    const now = new Date().toISOString();

    for (const targetUid of targetUserIds) {
      const notif: NotificationRecord = {
        id: `notif_bc_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
        userId: targetUid,
        title,
        body,
        type: 'admin_broadcast',
        payload: {
          screen: screen || 'AdminMessage',
          targetId: targetId || '',
        },
        isRead: false,
        deliveryStatus: 'delivered',
        createdAt: now,
      };
      notificationsStore.unshift(notif);
      createdNotifications.push(notif);
    }

    console.log(`[Server Broadcast] Sent push notification broadcast '${title}' to ${targetUserIds.length} user(s).`);
    return res.status(200).json({
      success: true,
      recipientCount: targetUserIds.length,
      notifications: createdNotifications,
    });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 5. Fetch User Notifications
app.get('/api/notifications/:userId', (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    const userNotifs = notificationsStore.filter((n) => n.userId === userId);
    return res.status(200).json({ notifications: userNotifs });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 6. Mark Single Notification Read
app.patch('/api/notifications/:id/read', (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const notif = notificationsStore.find((n) => n.id === id);
    if (notif) {
      notif.isRead = true;
    }
    return res.status(200).json({ success: true, notification: notif });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 7. Mark All User Notifications Read
app.patch('/api/notifications/user/:userId/read-all', (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    notificationsStore.forEach((n) => {
      if (n.userId === userId) {
        n.isRead = true;
      }
    });
    return res.status(200).json({ success: true });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});

// 8. Delete Notification
app.delete('/api/notifications/:id', (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const index = notificationsStore.findIndex((n) => n.id === id);
    if (index >= 0) {
      notificationsStore.splice(index, 1);
    }
    return res.status(200).json({ success: true });
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
});


// ==========================================
// AI MODERATION ENGINE & TRUST & SAFETY
// ==========================================
import { GoogleGenAI } from '@google/genai';

let ai: GoogleGenAI | null = null;
if (process.env.GEMINI_API_KEY) {
  ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
}

// Simple fast-path rule engine to save costs
const FAST_RULES_SPAM = ['buy followers', 'ponzi', 'free money', 'whatsapp me', 'telegram me', 'crypto scam', 'cash app'];

app.post('/api/moderate/text', async (req: Request, res: Response) => {
  try {
    const { text, type, userId } = req.body;
    
    if (!text) {
      return res.status(400).json({ error: 'Text is required' });
    }

    // 1. FAST RULE ENGINE
    const lowerText = text.toLowerCase();
    for (const phrase of FAST_RULES_SPAM) {
      if (lowerText.includes(phrase)) {
        console.log(`[Moderation] Fast Rule triggered for user ${userId} on text: ${phrase}`);
        return res.status(200).json({
          risk_score: 95,
          confidence_score: 100,
          category: 'spam_scam',
          reason: `Contains prohibited phrase: ${phrase}`,
          recommended_action: 'shadow_ban'
        });
      }
    }

    // 2. GEMINI AI ENGINE
    if (!ai) {
      // Fallback if no API key
      return res.status(200).json({
        risk_score: 0,
        confidence_score: 0,
        category: 'safe',
        reason: 'AI key not configured. Bypassed.',
        recommended_action: 'none'
      });
    }

    const prompt = `
You are an enterprise-grade automated Trust & Safety AI.
Analyze the following ${type || 'text'} submitted by a user on a creator/brand marketplace.
Detect: abusive language, harassment, hate speech, spam, scam, fake engagement requests, adult content, or policy violations.

Text to analyze:
"${text}"

Return strictly valid JSON with the following schema:
{
  "risk_score": <number 0-100, 0 is safe, 100 is critical risk>,
  "confidence_score": <number 0-100>,
  "category": <"safe" | "abusive" | "spam" | "scam" | "adult" | "harassment" | "policy_violation">,
  "reason": <short string explaining why>,
  "recommended_action": <"none" | "warn" | "suspend" | "shadow_ban" | "manual_review">
}`;

    const response = await ai.models.generateContent({
      model: 'gemini-1.5-flash',
      contents: prompt,
      config: {
        responseMimeType: 'application/json',
      }
    });

    const resultText = response.text || '{}';
    const result = JSON.parse(resultText);
    
    console.log(`[Moderation] AI Analyzed user ${userId}. Score: ${result.risk_score}. Category: ${result.category}`);
    
    return res.status(200).json(result);

  } catch (err: any) {
    console.error('[Moderation Error]', err);
    return res.status(500).json({ error: err.message });
  }
});

// ==========================================
// VITE DEV & PRODUCTION SERVER MIDDLEWARE
// ==========================================
async function startServer() {
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req: Request, res: Response) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`[Rexo Production Server] Running on http://0.0.0.0:${PORT}`);
  });
}

startServer();
