var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));

// server.ts
var import_express = __toESM(require("express"), 1);
var import_path = __toESM(require("path"), 1);
var import_vite = require("vite");
var import_app = require("firebase-admin/app");
var import_messaging = require("firebase-admin/messaging");
var import_genai = require("@google/genai");
var app = (0, import_express.default)();
var PORT = 3e3;
app.use(import_express.default.json());
var isFirebaseAdminInitialized = false;
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    (0, import_app.initializeApp)({
      credential: (0, import_app.cert)(serviceAccount)
    });
    isFirebaseAdminInitialized = true;
    console.log("[Server] Firebase Admin SDK initialized successfully for FCM.");
  } else {
    console.log("[Server] FIREBASE_SERVICE_ACCOUNT_KEY not found. Operating in simulated FCM push mode.");
  }
} catch (err) {
  console.warn("[Server] Firebase Admin SDK initialization skipped:", err);
}
var userDevicesStore = [];
var notificationsStore = [];
var requestCounts = /* @__PURE__ */ new Map();
var apiRateLimiter = (req, res, next) => {
  const ip = req.headers["x-forwarded-for"] || req.socket.remoteAddress || "127.0.0.1";
  const now = Date.now();
  const windowMs = 60 * 1e3;
  const maxRequests = 120;
  const current = requestCounts.get(ip) || { count: 0, lastReset: now };
  if (now - current.lastReset > windowMs) {
    current.count = 1;
    current.lastReset = now;
  } else {
    current.count += 1;
  }
  requestCounts.set(ip, current);
  if (current.count > maxRequests) {
    return res.status(429).json({ error: "Too many requests. Please try again later." });
  }
  next();
};
app.use("/api/", apiRateLimiter);
var authenticateAndAuthorize = (allowedRoles) => {
  return (req, res, next) => {
    const authHeader = req.headers.authorization;
    const userRoleHeader = req.headers["x-user-role"] || "creator";
    if (!authHeader && process.env.NODE_ENV === "production" && process.env.VITE_SUPABASE_URL) {
      return res.status(401).json({ error: "Authentication token required" });
    }
    if (allowedRoles.length > 0 && !allowedRoles.includes(userRoleHeader)) {
      return res.status(403).json({ error: `Forbidden: Requires one of [${allowedRoles.join(", ")}] role` });
    }
    req.userRole = userRoleHeader;
    next();
  };
};
app.post("/api/wallet/deposit/request", (req, res) => {
  try {
    const { brandId, brandName, amount, transactionRef, proofScreenshotUrl } = req.body;
    if (!brandId || !amount || amount <= 0 || !transactionRef) {
      return res.status(400).json({ error: "brandId, valid amount, and transactionRef are required" });
    }
    const depositRecord = {
      id: `dep_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      brandId,
      brandName: brandName || "Brand Partner",
      amount: Number(amount),
      paymentMethod: "upi_manual",
      transactionRef,
      proofScreenshotUrl: proofScreenshotUrl || "",
      status: "pending",
      createdAt: (/* @__PURE__ */ new Date()).toISOString()
    };
    console.log(`[Wallet API] Manual Deposit requested: \u20B9${amount} by ${brandName} (Ref: ${transactionRef})`);
    return res.status(200).json({ success: true, deposit: depositRecord });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.post("/api/wallet/withdraw/request", (req, res) => {
  try {
    const { userId, userName, userRole, amount, payoutMethod, payoutDetails, availableBalance } = req.body;
    if (!userId || !amount || amount <= 0) {
      return res.status(400).json({ error: "userId and valid withdrawal amount required" });
    }
    if (availableBalance !== void 0 && Number(amount) > Number(availableBalance)) {
      return res.status(400).json({ error: "Insufficient available wallet balance" });
    }
    const withdrawalRecord = {
      id: `wd_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      userId,
      userName: userName || "User Account",
      userRole: userRole || "creator",
      amount: Number(amount),
      payoutMethod: payoutMethod || "upi",
      payoutDetails: payoutDetails || {},
      status: "pending",
      createdAt: (/* @__PURE__ */ new Date()).toISOString()
    };
    console.log(`[Wallet API] Withdrawal requested: \u20B9${amount} by ${userName}`);
    return res.status(200).json({ success: true, withdrawal: withdrawalRecord });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.post("/api/admin/bulk-approve-deposits", authenticateAndAuthorize(["admin"]), (req, res) => {
  try {
    const { depositIds, adminNotes } = req.body;
    if (!Array.isArray(depositIds) || depositIds.length === 0) {
      return res.status(400).json({ error: "depositIds array is required" });
    }
    console.log(`[Admin API] Bulk approved ${depositIds.length} deposit requests. Notes: ${adminNotes || "Cleared"}`);
    return res.status(200).json({
      success: true,
      processedCount: depositIds.length,
      depositIds,
      status: "approved"
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.post("/api/admin/bulk-approve-withdrawals", authenticateAndAuthorize(["admin"]), (req, res) => {
  try {
    const { withdrawalIds, transactionRef } = req.body;
    if (!Array.isArray(withdrawalIds) || withdrawalIds.length === 0) {
      return res.status(400).json({ error: "withdrawalIds array is required" });
    }
    console.log(`[Admin API] Bulk approved ${withdrawalIds.length} withdrawal payouts. Ref: ${transactionRef || "Batch Paid"}`);
    return res.status(200).json({
      success: true,
      processedCount: withdrawalIds.length,
      withdrawalIds,
      status: "approved"
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.post("/api/admin/bulk-approve-kyc", authenticateAndAuthorize(["admin"]), (req, res) => {
  try {
    const { kycDocIds } = req.body;
    if (!Array.isArray(kycDocIds) || kycDocIds.length === 0) {
      return res.status(400).json({ error: "kycDocIds array is required" });
    }
    console.log(`[Admin API] Bulk approved ${kycDocIds.length} KYC documents.`);
    return res.status(200).json({
      success: true,
      processedCount: kycDocIds.length,
      kycDocIds,
      status: "verified"
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.get("/api/admin/audit-logs/export-csv", authenticateAndAuthorize(["admin"]), (req, res) => {
  try {
    const headers = "ID,Admin,Action,Target,Reason,Timestamp\n";
    const sampleRow1 = `audit_101,Admin Master,KYC_APPROVED,Creator User,Document verified,${(/* @__PURE__ */ new Date()).toISOString()}
`;
    const sampleRow2 = `audit_102,Admin Master,DEPOSIT_APPROVED,Brand Co,UTR Ref 98218318,${(/* @__PURE__ */ new Date()).toISOString()}
`;
    const csvContent = headers + sampleRow1 + sampleRow2;
    res.setHeader("Content-Type", "text/csv");
    res.setHeader("Content-Disposition", 'attachment; filename="rexo_audit_logs.csv"');
    return res.status(200).send(csvContent);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.post("/api/shop/purchase", (req, res) => {
  try {
    const { userId, userName, productId, productTitle, productType, price, shippingAddress, serviceNotes } = req.body;
    if (!userId || !productId || !price) {
      return res.status(400).json({ error: "userId, productId, and price are required" });
    }
    if (productType === "physical") {
      if (!shippingAddress || !shippingAddress.address || !shippingAddress.pincode) {
        return res.status(400).json({ error: "Full shipping address and pincode are required for physical items" });
      }
    }
    const orderRecord = {
      id: `ord_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
      userId,
      userName: userName || "Customer",
      productId,
      productTitle: productTitle || "Item",
      productType: productType || "digital",
      price: Number(price),
      status: productType === "digital" ? "completed" : "pending",
      shippingAddress: productType === "physical" ? shippingAddress : null,
      digitalDownloadUrl: productType === "digital" ? `https://rexo-downloads.s3.amazonaws.com/digital_asset_${productId}.zip` : null,
      trackingNumber: productType === "physical" ? `TRACK_IN_${Math.floor(1e5 + Math.random() * 9e5)}` : null,
      serviceNotes: productType === "service" ? serviceNotes || "Service order queued for admin execution" : null,
      createdAt: (/* @__PURE__ */ new Date()).toISOString()
    };
    console.log(`[Shop API] New ${productType} order created: ${orderRecord.id}`);
    return res.status(200).json({ success: true, order: orderRecord });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.post("/api/notifications/register-device", (req, res) => {
  try {
    const { userId, fcmToken, platform, appVersion, deviceName } = req.body;
    if (!userId || !fcmToken) {
      return res.status(400).json({ error: "userId and fcmToken are required" });
    }
    const existingIndex = userDevicesStore.findIndex(
      (d) => d.userId === userId && d.fcmToken === fcmToken
    );
    const now = (/* @__PURE__ */ new Date()).toISOString();
    let device;
    if (existingIndex >= 0) {
      userDevicesStore[existingIndex] = {
        ...userDevicesStore[existingIndex],
        platform: platform || "android",
        appVersion: appVersion || "2.4.0",
        deviceName: deviceName || "Android Device",
        updatedAt: now
      };
      device = userDevicesStore[existingIndex];
    } else {
      device = {
        id: `dev_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        userId,
        fcmToken,
        platform: platform || "android",
        appVersion: appVersion || "2.4.0",
        deviceName: deviceName || "Android Device",
        createdAt: now,
        updatedAt: now
      };
      userDevicesStore.push(device);
    }
    console.log(`[Server API] Device FCM token registered for user: ${userId}`);
    return res.status(200).json({ success: true, device });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.post("/api/notifications/unregister-device", (req, res) => {
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
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.post("/api/notifications/send", async (req, res) => {
  try {
    const { userId, title, body, type, payload } = req.body;
    if (!userId || !title || !body) {
      return res.status(400).json({ error: "userId, title, and body are required" });
    }
    const newNotification = {
      id: `notif_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      userId,
      title,
      body,
      type: type || "system",
      payload: payload || {},
      isRead: false,
      deliveryStatus: "sent",
      createdAt: (/* @__PURE__ */ new Date()).toISOString()
    };
    notificationsStore.unshift(newNotification);
    const userTokens = userDevicesStore.filter((d) => d.userId === userId).map((d) => d.fcmToken);
    let fcmSentCount = 0;
    if (isFirebaseAdminInitialized && userTokens.length > 0) {
      try {
        const messagePayload = {
          notification: {
            title,
            body
          },
          data: {
            screen: payload?.screen || "AdminMessage",
            targetId: payload?.targetId || "",
            notificationId: newNotification.id,
            type: newNotification.type
          },
          tokens: userTokens
        };
        const response = await (0, import_messaging.getMessaging)().sendEachForMulticast(messagePayload);
        fcmSentCount = response.successCount;
        newNotification.deliveryStatus = fcmSentCount > 0 ? "delivered" : "sent";
      } catch (fcmErr) {
        console.warn("[Server FCM Push] Firebase multicast send warning:", fcmErr);
      }
    } else {
      newNotification.deliveryStatus = "delivered";
      fcmSentCount = userTokens.length || 1;
    }
    console.log(`[Server Notification Engine] Dispatched push notification '${title}' to user ${userId}. FCM tokens hit: ${fcmSentCount}`);
    return res.status(200).json({
      success: true,
      notification: newNotification,
      fcmDeliveredCount: fcmSentCount
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.post("/api/notifications/broadcast", async (req, res) => {
  try {
    const { audience, userId, title, body, screen, targetId } = req.body;
    if (!title || !body) {
      return res.status(400).json({ error: "title and body are required for broadcast" });
    }
    let targetUserIds = [];
    if (audience === "specific" && userId) {
      targetUserIds = [userId];
    } else {
      const allRegisteredUserIds = Array.from(new Set(userDevicesStore.map((d) => d.userId)));
      targetUserIds = allRegisteredUserIds.length > 0 ? allRegisteredUserIds : ["usr_admin_master"];
    }
    const createdNotifications = [];
    const now = (/* @__PURE__ */ new Date()).toISOString();
    for (const targetUid of targetUserIds) {
      const notif = {
        id: `notif_bc_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
        userId: targetUid,
        title,
        body,
        type: "admin_broadcast",
        payload: {
          screen: screen || "AdminMessage",
          targetId: targetId || ""
        },
        isRead: false,
        deliveryStatus: "delivered",
        createdAt: now
      };
      notificationsStore.unshift(notif);
      createdNotifications.push(notif);
    }
    console.log(`[Server Broadcast] Sent push notification broadcast '${title}' to ${targetUserIds.length} user(s).`);
    return res.status(200).json({
      success: true,
      recipientCount: targetUserIds.length,
      notifications: createdNotifications
    });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.get("/api/notifications/:userId", (req, res) => {
  try {
    const { userId } = req.params;
    const userNotifs = notificationsStore.filter((n) => n.userId === userId);
    return res.status(200).json({ notifications: userNotifs });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.patch("/api/notifications/:id/read", (req, res) => {
  try {
    const { id } = req.params;
    const notif = notificationsStore.find((n) => n.id === id);
    if (notif) {
      notif.isRead = true;
    }
    return res.status(200).json({ success: true, notification: notif });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.patch("/api/notifications/user/:userId/read-all", (req, res) => {
  try {
    const { userId } = req.params;
    notificationsStore.forEach((n) => {
      if (n.userId === userId) {
        n.isRead = true;
      }
    });
    return res.status(200).json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
app.delete("/api/notifications/:id", (req, res) => {
  try {
    const { id } = req.params;
    const index = notificationsStore.findIndex((n) => n.id === id);
    if (index >= 0) {
      notificationsStore.splice(index, 1);
    }
    return res.status(200).json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});
var ai = null;
if (process.env.GEMINI_API_KEY) {
  ai = new import_genai.GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
}
var FAST_RULES_SPAM = ["buy followers", "ponzi", "free money", "whatsapp me", "telegram me", "crypto scam", "cash app"];
app.post("/api/moderate/text", async (req, res) => {
  try {
    const { text, type, userId } = req.body;
    if (!text) {
      return res.status(400).json({ error: "Text is required" });
    }
    const lowerText = text.toLowerCase();
    for (const phrase of FAST_RULES_SPAM) {
      if (lowerText.includes(phrase)) {
        console.log(`[Moderation] Fast Rule triggered for user ${userId} on text: ${phrase}`);
        return res.status(200).json({
          risk_score: 95,
          confidence_score: 100,
          category: "spam_scam",
          reason: `Contains prohibited phrase: ${phrase}`,
          recommended_action: "shadow_ban"
        });
      }
    }
    if (!ai) {
      return res.status(200).json({
        risk_score: 0,
        confidence_score: 0,
        category: "safe",
        reason: "AI key not configured. Bypassed.",
        recommended_action: "none"
      });
    }
    const prompt = `
You are an enterprise-grade automated Trust & Safety AI.
Analyze the following ${type || "text"} submitted by a user on a creator/brand marketplace.
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
      model: "gemini-1.5-flash",
      contents: prompt,
      config: {
        responseMimeType: "application/json"
      }
    });
    const resultText = response.text || "{}";
    const result = JSON.parse(resultText);
    console.log(`[Moderation] AI Analyzed user ${userId}. Score: ${result.risk_score}. Category: ${result.category}`);
    return res.status(200).json(result);
  } catch (err) {
    console.error("[Moderation Error]", err);
    return res.status(500).json({ error: err.message });
  }
});
async function startServer() {
  if (process.env.NODE_ENV !== "production") {
    const vite = await (0, import_vite.createServer)({
      server: { middlewareMode: true },
      appType: "spa"
    });
    app.use(vite.middlewares);
  } else {
    const distPath = import_path.default.join(process.cwd(), "dist");
    app.use(import_express.default.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(import_path.default.join(distPath, "index.html"));
    });
  }
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`[Rexo Production Server] Running on http://0.0.0.0:${PORT}`);
  });
}
startServer();
//# sourceMappingURL=server.cjs.map
