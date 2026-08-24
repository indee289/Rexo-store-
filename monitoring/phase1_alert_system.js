/**
 * Phase 1 Critical Database Fixes - Real-time Alert System
 * 
 * This Node.js application provides real-time monitoring and alerting
 * for the Phase 1 database fixes using WebSockets and multiple notification channels.
 */

const { createClient } = require('@supabase/supabase-js');
const nodemailer = require('nodemailer');
const axios = require('axios');
const WebSocket = require('ws');
const cron = require('node-cron');

// Configuration
const config = {
    supabase: {
        url: process.env.SUPABASE_URL || 'http://localhost:54321',
        serviceKey: process.env.SUPABASE_SERVICE_ROLE_KEY || 'your-service-role-key'
    },
    notifications: {
        email: {
            smtp: {
                host: process.env.SMTP_HOST || 'smtp.gmail.com',
                port: process.env.SMTP_PORT || 587,
                secure: false,
                auth: {
                    user: process.env.SMTP_USER || 'alerts@rexomarketplace.com',
                    pass: process.env.SMTP_PASS || 'your-app-password'
                }
            },
            from: process.env.EMAIL_FROM || 'alerts@rexomarketplace.com',
            to: process.env.EMAIL_TO || 'admin@rexomarketplace.com'
        },
        slack: {
            webhookUrl: process.env.SLACK_WEBHOOK_URL || 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK',
            channel: process.env.SLACK_CHANNEL || '#database-alerts'
        },
        pagerduty: {
            integrationKey: process.env.PAGERDUTY_INTEGRATION_KEY || 'your-integration-key'
        }
    },
    monitoring: {
        checkInterval: parseInt(process.env.MONITOR_INTERVAL_SECONDS || '30'),
        errorThreshold: parseInt(process.env.ERROR_THRESHOLD_PERCENT || '5'),
        slowQueryThreshold: parseInt(process.env.SLOW_QUERY_THRESHOLD_MS || '1000'),
        websocketPort: parseInt(process.env.WEBSOCKET_PORT || '8080')
    }
};

class Phase1AlertSystem {
    constructor() {
        this.supabase = createClient(config.supabase.url, config.supabase.serviceKey);
        this.emailTransporter = this.setupEmailTransporter();
        this.websocketServer = null;
        this.activeAlerts = new Map();
        this.alertHistory = [];
        this.isRunning = false;
    }

    // Initialize the alert system
    async initialize() {
        console.log('🚀 Initializing Phase 1 Alert System...');
        
        try {
            // Test database connection
            await this.testDatabaseConnection();
            
            // Setup WebSocket server for real-time alerts
            this.setupWebSocketServer();
            
            // Setup scheduled monitoring
            this.setupScheduledMonitoring();
            
            // Setup real-time database listeners
            this.setupRealtimeListeners();
            
            this.isRunning = true;
            console.log('✅ Phase 1 Alert System initialized successfully');
            
            // Send startup notification
            await this.sendAlert({
                severity: 'info',
                component: 'system',
                message: 'Phase 1 Alert System started',
                details: { timestamp: new Date().toISOString() }
            });
            
        } catch (error) {
            console.error('❌ Failed to initialize alert system:', error);
            process.exit(1);
        }
    }

    // Test database connection and monitoring setup
    async testDatabaseConnection() {
        console.log('🔍 Testing database connection...');
        
        const { data, error } = await this.supabase.rpc('check_phase1_health');
        
        if (error) {
            throw new Error(`Database connection failed: ${error.message}`);
        }
        
        console.log('✅ Database connection successful');
        console.log('📊 Health check results:', data);
    }

    // Setup email transporter
    setupEmailTransporter() {
        if (!config.notifications.email.smtp.auth.user || !config.notifications.email.smtp.auth.pass) {
            console.warn('⚠️ Email configuration incomplete - email alerts disabled');
            return null;
        }
        
        return nodemailer.createTransporter(config.notifications.email.smtp);
    }

    // Setup WebSocket server for real-time dashboard updates
    setupWebSocketServer() {
        console.log(`🌐 Starting WebSocket server on port ${config.monitoring.websocketPort}...`);
        
        this.websocketServer = new WebSocket.Server({ 
            port: config.monitoring.websocketPort,
            path: '/phase1-alerts'
        });
        
        this.websocketServer.on('connection', (ws) => {
            console.log('🔌 Dashboard client connected');
            
            // Send current alert status
            ws.send(JSON.stringify({
                type: 'status',
                data: {
                    activeAlerts: Array.from(this.activeAlerts.values()),
                    recentAlerts: this.alertHistory.slice(-10),
                    systemStatus: 'running'
                }
            }));
            
            ws.on('close', () => {
                console.log('🔌 Dashboard client disconnected');
            });
        });
        
        console.log('✅ WebSocket server started');
    }

    // Setup scheduled monitoring jobs
    setupScheduledMonitoring() {
        console.log('⏰ Setting up scheduled monitoring...');
        
        // Health check every minute
        cron.schedule('* * * * *', async () => {
            await this.performHealthCheck();
        });
        
        // Performance analysis every 5 minutes
        cron.schedule('*/5 * * * *', async () => {
            await this.analyzePerformance();
        });
        
        // Error analysis every 2 minutes
        cron.schedule('*/2 * * * *', async () => {
            await this.analyzeErrors();
        });
        
        // Daily summary report at 9 AM
        cron.schedule('0 9 * * *', async () => {
            await this.generateDailySummary();
        });
        
        console.log('✅ Scheduled monitoring configured');
    }

    // Setup real-time database listeners
    setupRealtimeListeners() {
        console.log('👂 Setting up real-time database listeners...');
        
        // Listen for performance metrics changes
        this.supabase
            .channel('phase1_performance_metrics')
            .on('postgres_changes', {
                event: 'INSERT',
                schema: 'public',
                table: 'phase1_performance_metrics'
            }, (payload) => {
                this.handlePerformanceMetricUpdate(payload.new);
            })
            .subscribe();
        
        // Listen for error log entries
        this.supabase
            .channel('phase1_error_log')
            .on('postgres_changes', {
                event: 'INSERT',
                schema: 'public',
                table: 'phase1_error_log'
            }, (payload) => {
                this.handleErrorLogUpdate(payload.new);
            })
            .subscribe();
        
        console.log('✅ Real-time listeners configured');
    }

    // Perform comprehensive health check
    async performHealthCheck() {
        try {
            const { data: healthResults, error } = await this.supabase.rpc('check_phase1_health');
            
            if (error) {
                await this.sendAlert({
                    severity: 'critical',
                    component: 'system',
                    message: 'Health check failed',
                    details: { error: error.message }
                });
                return;
            }
            
            // Process health results
            for (const result of healthResults) {
                const alertKey = `health_${result.component}`;
                
                if (result.status === 'critical') {
                    if (!this.activeAlerts.has(alertKey)) {
                        await this.sendAlert({
                            severity: 'critical',
                            component: result.component,
                            message: `Critical health issue detected`,
                            details: result.details,
                            alertKey
                        });
                    }
                } else if (result.status === 'warning') {
                    if (!this.activeAlerts.has(alertKey)) {
                        await this.sendAlert({
                            severity: 'warning',
                            component: result.component,
                            message: `Health warning detected`,
                            details: result.details,
                            alertKey
                        });
                    }
                } else if (result.status === 'healthy') {
                    // Clear any existing alerts for this component
                    if (this.activeAlerts.has(alertKey)) {
                        await this.clearAlert(alertKey, 'Health restored');
                    }
                }
            }
            
        } catch (error) {
            console.error('❌ Health check error:', error);
            await this.sendAlert({
                severity: 'critical',
                component: 'system',
                message: 'Health check exception',
                details: { error: error.message }
            });
        }
    }

    // Analyze performance metrics
    async analyzePerformance() {
        try {
            const { data: perfResults, error } = await this.supabase.rpc('analyze_phase1_performance', {
                p_component_name: null,
                p_time_period_hours: 1
            });
            
            if (error) {
                console.error('Performance analysis error:', error);
                return;
            }
            
            for (const result of perfResults) {
                const alertKey = `performance_${result.component}_${result.operation_type}`;
                
                // Check error rate threshold
                if (result.success_rate < (100 - config.monitoring.errorThreshold)) {
                    if (!this.activeAlerts.has(alertKey)) {
                        await this.sendAlert({
                            severity: 'warning',
                            component: result.component,
                            message: `High error rate detected: ${result.success_rate}%`,
                            details: {
                                operation_type: result.operation_type,
                                success_rate: result.success_rate,
                                total_operations: result.total_operations,
                                error_count: result.error_count
                            },
                            alertKey
                        });
                    }
                } else if (this.activeAlerts.has(alertKey)) {
                    await this.clearAlert(alertKey, 'Error rate normalized');
                }
                
                // Check slow query threshold
                const slowAlertKey = `slow_${result.component}_${result.operation_type}`;
                if (result.avg_execution_time > config.monitoring.slowQueryThreshold) {
                    if (!this.activeAlerts.has(slowAlertKey)) {
                        await this.sendAlert({
                            severity: 'warning',
                            component: result.component,
                            message: `Slow operations detected: ${result.avg_execution_time}ms average`,
                            details: {
                                operation_type: result.operation_type,
                                avg_execution_time: result.avg_execution_time,
                                max_execution_time: result.max_execution_time
                            },
                            alertKey: slowAlertKey
                        });
                    }
                } else if (this.activeAlerts.has(slowAlertKey)) {
                    await this.clearAlert(slowAlertKey, 'Performance improved');
                }
            }
            
        } catch (error) {
            console.error('❌ Performance analysis error:', error);
        }
    }

    // Analyze recent errors
    async analyzeErrors() {
        try {
            const { data: errors, error } = await this.supabase
                .from('phase1_error_log')
                .select('*')
                .gte('created_at', new Date(Date.now() - 10 * 60 * 1000).toISOString()) // Last 10 minutes
                .is('resolved_at', null)
                .order('created_at', { ascending: false });
            
            if (error) {
                console.error('Error analysis error:', error);
                return;
            }
            
            // Group errors by component and type
            const errorGroups = {};
            for (const errorRecord of errors) {
                const key = `${errorRecord.component_name}_${errorRecord.error_type}`;
                if (!errorGroups[key]) {
                    errorGroups[key] = {
                        component: errorRecord.component_name,
                        error_type: errorRecord.error_type,
                        count: 0,
                        latest: errorRecord.created_at,
                        messages: []
                    };
                }
                errorGroups[key].count++;
                errorGroups[key].messages.push(errorRecord.error_message);
            }
            
            // Send alerts for error groups
            for (const [key, group] of Object.entries(errorGroups)) {
                const alertKey = `errors_${key}`;
                
                if (group.count >= 3 && !this.activeAlerts.has(alertKey)) {
                    await this.sendAlert({
                        severity: 'warning',
                        component: group.component,
                        message: `Recurring errors detected: ${group.error_type} (${group.count} occurrences)`,
                        details: {
                            error_type: group.error_type,
                            count: group.count,
                            latest_error: group.latest,
                            sample_messages: group.messages.slice(0, 3)
                        },
                        alertKey
                    });
                }
            }
            
        } catch (error) {
            console.error('❌ Error analysis error:', error);
        }
    }

    // Handle real-time performance metric updates
    handlePerformanceMetricUpdate(metric) {
        // Broadcast to connected dashboards
        this.broadcastToClients({
            type: 'performance_update',
            data: metric
        });
        
        // Check for immediate alerts (e.g., very slow operations)
        if (metric.execution_time_ms > 5000) { // 5 second threshold for immediate alert
            this.sendAlert({
                severity: 'warning',
                component: metric.component_name,
                message: `Very slow operation detected: ${metric.execution_time_ms}ms`,
                details: {
                    operation_type: metric.operation_type,
                    execution_time: metric.execution_time_ms,
                    success: metric.success,
                    metadata: metric.metadata
                }
            });
        }
    }

    // Handle real-time error log updates
    handleErrorLogUpdate(errorRecord) {
        // Broadcast to connected dashboards
        this.broadcastToClients({
            type: 'error_update',
            data: errorRecord
        });
        
        // Send immediate alert for critical errors
        if (errorRecord.error_type.includes('critical') || errorRecord.error_type.includes('fatal')) {
            this.sendAlert({
                severity: 'critical',
                component: errorRecord.component_name,
                message: `Critical error occurred: ${errorRecord.error_type}`,
                details: {
                    error_message: errorRecord.error_message,
                    user_id: errorRecord.user_id,
                    request_context: errorRecord.request_context
                }
            });
        }
    }

    // Send alert through configured channels
    async sendAlert(alert) {
        const alertId = alert.alertKey || `${alert.component}_${Date.now()}`;
        const timestamp = new Date().toISOString();
        
        const fullAlert = {
            ...alert,
            id: alertId,
            timestamp,
            status: 'active'
        };
        
        console.log(`🚨 ALERT [${alert.severity.toUpperCase()}]: ${alert.message}`);
        
        // Store active alert
        if (alert.alertKey) {
            this.activeAlerts.set(alert.alertKey, fullAlert);
        }
        
        // Add to history
        this.alertHistory.push(fullAlert);
        if (this.alertHistory.length > 100) {
            this.alertHistory = this.alertHistory.slice(-100);
        }
        
        // Send notifications based on severity
        const notifications = [];
        
        if (alert.severity === 'critical') {
            notifications.push(
                this.sendEmailAlert(fullAlert),
                this.sendSlackAlert(fullAlert),
                this.sendPagerDutyAlert(fullAlert)
            );
        } else if (alert.severity === 'warning') {
            notifications.push(
                this.sendEmailAlert(fullAlert),
                this.sendSlackAlert(fullAlert)
            );
        } else {
            notifications.push(this.sendSlackAlert(fullAlert));
        }
        
        // Broadcast to connected dashboards
        this.broadcastToClients({
            type: 'new_alert',
            data: fullAlert
        });
        
        try {
            await Promise.all(notifications);
        } catch (error) {
            console.error('❌ Failed to send alert notifications:', error);
        }
    }

    // Clear an active alert
    async clearAlert(alertKey, reason) {
        const alert = this.activeAlerts.get(alertKey);
        if (alert) {
            alert.status = 'resolved';
            alert.resolvedAt = new Date().toISOString();
            alert.resolution = reason;
            
            console.log(`✅ RESOLVED: ${alert.message} (${reason})`);
            
            this.activeAlerts.delete(alertKey);
            
            // Broadcast resolution
            this.broadcastToClients({
                type: 'alert_resolved',
                data: alert
            });
        }
    }

    // Send email alert
    async sendEmailAlert(alert) {
        if (!this.emailTransporter) return;
        
        const subject = `[${alert.severity.toUpperCase()}] Phase 1 Alert: ${alert.component}`;
        const html = `
            <h2>Phase 1 Database Alert</h2>
            <p><strong>Component:</strong> ${alert.component}</p>
            <p><strong>Severity:</strong> ${alert.severity.toUpperCase()}</p>
            <p><strong>Message:</strong> ${alert.message}</p>
            <p><strong>Timestamp:</strong> ${alert.timestamp}</p>
            ${alert.details ? `<pre><strong>Details:</strong>\n${JSON.stringify(alert.details, null, 2)}</pre>` : ''}
            
            <hr>
            <p><em>This alert was generated by the Rexo Marketplace Phase 1 Monitoring System</em></p>
        `;
        
        try {
            await this.emailTransporter.sendMail({
                from: config.notifications.email.from,
                to: config.notifications.email.to,
                subject,
                html
            });
        } catch (error) {
            console.error('❌ Email alert failed:', error);
        }
    }

    // Send Slack alert
    async sendSlackAlert(alert) {
        if (!config.notifications.slack.webhookUrl || config.notifications.slack.webhookUrl.includes('YOUR')) return;
        
        const color = {
            'critical': '#FF0000',
            'warning': '#FFA500',
            'info': '#0099FF'
        }[alert.severity] || '#808080';
        
        const payload = {
            channel: config.notifications.slack.channel,
            attachments: [{
                color,
                title: `Phase 1 Alert: ${alert.component}`,
                text: alert.message,
                fields: [
                    {
                        title: 'Severity',
                        value: alert.severity.toUpperCase(),
                        short: true
                    },
                    {
                        title: 'Component',
                        value: alert.component,
                        short: true
                    },
                    {
                        title: 'Timestamp',
                        value: alert.timestamp,
                        short: false
                    }
                ],
                footer: 'Rexo Marketplace Phase 1 Monitor',
                ts: Math.floor(Date.now() / 1000)
            }]
        };
        
        if (alert.details) {
            payload.attachments[0].fields.push({
                title: 'Details',
                value: `\`\`\`${JSON.stringify(alert.details, null, 2)}\`\`\``,
                short: false
            });
        }
        
        try {
            await axios.post(config.notifications.slack.webhookUrl, payload);
        } catch (error) {
            console.error('❌ Slack alert failed:', error);
        }
    }

    // Send PagerDuty alert
    async sendPagerDutyAlert(alert) {
        if (!config.notifications.pagerduty.integrationKey || config.notifications.pagerduty.integrationKey.includes('your')) return;
        
        const payload = {
            routing_key: config.notifications.pagerduty.integrationKey,
            event_action: 'trigger',
            dedup_key: alert.id,
            payload: {
                summary: `Phase 1 ${alert.component}: ${alert.message}`,
                severity: alert.severity === 'critical' ? 'critical' : 'warning',
                source: 'rexo-phase1-monitor',
                component: alert.component,
                group: 'database',
                class: 'phase1-fixes',
                custom_details: alert.details
            }
        };
        
        try {
            await axios.post('https://events.pagerduty.com/v2/enqueue', payload);
        } catch (error) {
            console.error('❌ PagerDuty alert failed:', error);
        }
    }

    // Broadcast message to all connected WebSocket clients
    broadcastToClients(message) {
        if (!this.websocketServer) return;
        
        this.websocketServer.clients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(JSON.stringify(message));
            }
        });
    }

    // Generate daily summary report
    async generateDailySummary() {
        console.log('📊 Generating daily summary report...');
        
        try {
            const { data: healthData, error: healthError } = await this.supabase.rpc('check_phase1_health');
            const { data: perfData, error: perfError } = await this.supabase.rpc('analyze_phase1_performance', {
                p_component_name: null,
                p_time_period_hours: 24
            });
            
            if (healthError || perfError) {
                console.error('❌ Failed to generate daily summary:', healthError || perfError);
                return;
            }
            
            const summary = {
                date: new Date().toISOString().split('T')[0],
                health_status: healthData,
                performance_metrics: perfData,
                total_alerts: this.alertHistory.filter(a => 
                    new Date(a.timestamp).toDateString() === new Date().toDateString()
                ).length,
                critical_alerts: this.alertHistory.filter(a => 
                    a.severity === 'critical' && 
                    new Date(a.timestamp).toDateString() === new Date().toDateString()
                ).length,
                active_alerts: this.activeAlerts.size
            };
            
            // Send summary email
            if (this.emailTransporter) {
                const html = `
                    <h2>Phase 1 Daily Summary - ${summary.date}</h2>
                    <h3>Health Status</h3>
                    <ul>
                        ${summary.health_status.map(h => 
                            `<li><strong>${h.component}:</strong> ${h.status}</li>`
                        ).join('')}
                    </ul>
                    
                    <h3>Alert Summary</h3>
                    <ul>
                        <li>Total Alerts: ${summary.total_alerts}</li>
                        <li>Critical Alerts: ${summary.critical_alerts}</li>
                        <li>Currently Active: ${summary.active_alerts}</li>
                    </ul>
                    
                    <h3>Performance Overview</h3>
                    <table border="1" style="border-collapse: collapse;">
                        <tr><th>Component</th><th>Operation</th><th>Success Rate</th><th>Avg Time</th></tr>
                        ${summary.performance_metrics.map(p => 
                            `<tr><td>${p.component}</td><td>${p.operation_type}</td><td>${p.success_rate}%</td><td>${p.avg_execution_time}ms</td></tr>`
                        ).join('')}
                    </table>
                `;
                
                await this.emailTransporter.sendMail({
                    from: config.notifications.email.from,
                    to: config.notifications.email.to,
                    subject: `Phase 1 Daily Summary - ${summary.date}`,
                    html
                });
            }
            
            console.log('✅ Daily summary report generated and sent');
            
        } catch (error) {
            console.error('❌ Failed to generate daily summary:', error);
        }
    }

    // Graceful shutdown
    async shutdown() {
        console.log('🛑 Shutting down Phase 1 Alert System...');
        
        this.isRunning = false;
        
        if (this.websocketServer) {
            this.websocketServer.close();
        }
        
        // Send shutdown notification
        await this.sendAlert({
            severity: 'info',
            component: 'system',
            message: 'Phase 1 Alert System shutting down',
            details: { timestamp: new Date().toISOString() }
        });
        
        console.log('✅ Phase 1 Alert System shutdown complete');
    }
}

// Initialize and start the alert system
const alertSystem = new Phase1AlertSystem();

// Graceful shutdown handling
process.on('SIGINT', async () => {
    await alertSystem.shutdown();
    process.exit(0);
});

process.on('SIGTERM', async () => {
    await alertSystem.shutdown();
    process.exit(0);
});

// Start the system
alertSystem.initialize().catch((error) => {
    console.error('❌ Failed to start alert system:', error);
    process.exit(1);
});

module.exports = Phase1AlertSystem;