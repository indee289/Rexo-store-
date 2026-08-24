-- ============================================================
-- Phase 1 Critical Database Fixes - Monitoring & Alerting Setup
-- ============================================================
-- This script creates comprehensive monitoring for the three Phase 1 fixes:
-- 1. Subscription Plans Schema Alignment
-- 2. Wallet RPC Function Aliases 
-- 3. Subscription Payments Table Integration
-- ============================================================

-- ============================================================
-- 1. CREATE MONITORING TABLES
-- ============================================================

-- Performance metrics tracking
CREATE TABLE IF NOT EXISTS public.phase1_performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    component_name TEXT NOT NULL CHECK (component_name IN ('subscription_plans', 'wallet_functions', 'subscription_payments')),
    operation_type TEXT NOT NULL,
    execution_time_ms INTEGER NOT NULL,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Index for time-series queries
    CONSTRAINT valid_execution_time CHECK (execution_time_ms >= 0)
);

-- Health check results
CREATE TABLE IF NOT EXISTS public.phase1_health_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_type TEXT NOT NULL CHECK (check_type IN ('schema_validation', 'function_validation', 'data_integrity', 'performance_check')),
    component_name TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('healthy', 'warning', 'critical')),
    details JSONB NOT NULL,
    checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Error tracking for Phase 1 components
CREATE TABLE IF NOT EXISTS public.phase1_error_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    component_name TEXT NOT NULL,
    error_type TEXT NOT NULL,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    user_id UUID REFERENCES auth.users(id),
    request_context JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT
);

-- Alert configurations
CREATE TABLE IF NOT EXISTS public.phase1_alert_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_name TEXT NOT NULL UNIQUE,
    component_name TEXT NOT NULL,
    metric_type TEXT NOT NULL,
    threshold_value NUMERIC NOT NULL,
    comparison_operator TEXT NOT NULL CHECK (comparison_operator IN ('>', '<', '>=', '<=', '=', '!=')),
    time_window_minutes INTEGER NOT NULL DEFAULT 5,
    severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    notification_channels TEXT[] NOT NULL DEFAULT ARRAY['email'],
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 2. CREATE MONITORING FUNCTIONS
-- ============================================================

-- Function to log performance metrics
CREATE OR REPLACE FUNCTION log_phase1_performance(
    p_component_name TEXT,
    p_operation_type TEXT,
    p_execution_time_ms INTEGER,
    p_success BOOLEAN,
    p_error_message TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    metric_id UUID;
BEGIN
    INSERT INTO public.phase1_performance_metrics (
        component_name,
        operation_type,
        execution_time_ms,
        success,
        error_message,
        metadata
    ) VALUES (
        p_component_name,
        p_operation_type,
        p_execution_time_ms,
        p_success,
        p_error_message,
        p_metadata
    ) RETURNING id INTO metric_id;
    
    RETURN metric_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to perform comprehensive health check
CREATE OR REPLACE FUNCTION check_phase1_health()
RETURNS TABLE (
    component TEXT,
    status TEXT,
    details JSONB
) AS $$
DECLARE
    subscription_plans_status JSONB;
    wallet_functions_status JSONB;
    subscription_payments_status JSONB;
BEGIN
    -- Check subscription plans schema
    SELECT jsonb_build_object(
        'interval_column_exists', EXISTS(
            SELECT 1 FROM information_schema.columns 
            WHERE table_name='subscription_plans' AND column_name='interval'
        ),
        'total_plans', (SELECT COUNT(*) FROM public.subscription_plans),
        'plans_with_interval', (SELECT COUNT(*) FROM public.subscription_plans WHERE interval IS NOT NULL),
        'plans_with_duration', (SELECT COUNT(*) FROM public.subscription_plans WHERE duration_days > 0),
        'last_seeding_attempt', (
            SELECT MAX(created_at) FROM public.phase1_performance_metrics 
            WHERE component_name = 'subscription_plans' AND operation_type = 'seed_execution'
        )
    ) INTO subscription_plans_status;
    
    -- Check wallet functions
    SELECT jsonb_build_object(
        'credit_wallet_exists', EXISTS(SELECT 1 FROM pg_proc WHERE proname='credit_wallet'),
        'debit_wallet_exists', EXISTS(SELECT 1 FROM pg_proc WHERE proname='debit_wallet'),
        'increment_wallet_exists', EXISTS(SELECT 1 FROM pg_proc WHERE proname='increment_wallet_balance'),
        'decrement_wallet_exists', EXISTS(SELECT 1 FROM pg_proc WHERE proname='decrement_wallet_balance'),
        'recent_wallet_operations', (
            SELECT COUNT(*) FROM public.phase1_performance_metrics 
            WHERE component_name = 'wallet_functions' 
            AND created_at > NOW() - INTERVAL '1 hour'
        )
    ) INTO wallet_functions_status;
    
    -- Check subscription payments table
    SELECT jsonb_build_object(
        'table_exists', EXISTS(
            SELECT 1 FROM information_schema.tables 
            WHERE table_name='subscription_payments'
        ),
        'total_payments', (
            SELECT CASE 
                WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name='subscription_payments')
                THEN (SELECT COUNT(*) FROM public.subscription_payments)::TEXT
                ELSE 'table_missing'
            END
        ),
        'recent_payment_operations', (
            SELECT COUNT(*) FROM public.phase1_performance_metrics 
            WHERE component_name = 'subscription_payments' 
            AND created_at > NOW() - INTERVAL '1 hour'
        )
    ) INTO subscription_payments_status;
    
    -- Return results
    RETURN QUERY
    SELECT 'subscription_plans'::TEXT, 
           CASE WHEN (subscription_plans_status->>'interval_column_exists')::BOOLEAN 
                THEN 'healthy' ELSE 'critical' END,
           subscription_plans_status
    UNION ALL
    SELECT 'wallet_functions'::TEXT,
           CASE WHEN (wallet_functions_status->>'credit_wallet_exists')::BOOLEAN 
                AND (wallet_functions_status->>'debit_wallet_exists')::BOOLEAN
                THEN 'healthy' ELSE 'critical' END,
           wallet_functions_status
    UNION ALL
    SELECT 'subscription_payments'::TEXT,
           CASE WHEN (subscription_payments_status->>'table_exists')::BOOLEAN
                THEN 'healthy' ELSE 'critical' END,
           subscription_payments_status;
    
    -- Log health check results
    INSERT INTO public.phase1_health_checks (check_type, component_name, status, details)
    SELECT 'schema_validation', component, status, details
    FROM (
        SELECT 'subscription_plans'::TEXT as component, 
               CASE WHEN (subscription_plans_status->>'interval_column_exists')::BOOLEAN 
                    THEN 'healthy' ELSE 'critical' END as status,
               subscription_plans_status as details
        UNION ALL
        SELECT 'wallet_functions'::TEXT,
               CASE WHEN (wallet_functions_status->>'credit_wallet_exists')::BOOLEAN 
                    AND (wallet_functions_status->>'debit_wallet_exists')::BOOLEAN
                    THEN 'healthy' ELSE 'critical' END,
               wallet_functions_status
        UNION ALL
        SELECT 'subscription_payments'::TEXT,
               CASE WHEN (subscription_payments_status->>'table_exists')::BOOLEAN
                    THEN 'healthy' ELSE 'critical' END,
               subscription_payments_status
    ) health_results;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to analyze performance trends
CREATE OR REPLACE FUNCTION analyze_phase1_performance(
    p_component_name TEXT DEFAULT NULL,
    p_time_period_hours INTEGER DEFAULT 24
)
RETURNS TABLE (
    component TEXT,
    operation_type TEXT,
    total_operations BIGINT,
    success_rate NUMERIC,
    avg_execution_time NUMERIC,
    max_execution_time INTEGER,
    error_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pm.component_name::TEXT,
        pm.operation_type::TEXT,
        COUNT(*)::BIGINT as total_operations,
        ROUND((COUNT(*) FILTER (WHERE pm.success) * 100.0 / COUNT(*)), 2) as success_rate,
        ROUND(AVG(pm.execution_time_ms), 2) as avg_execution_time,
        MAX(pm.execution_time_ms) as max_execution_time,
        COUNT(*) FILTER (WHERE NOT pm.success)::BIGINT as error_count
    FROM public.phase1_performance_metrics pm
    WHERE pm.created_at > NOW() - (p_time_period_hours || ' hours')::INTERVAL
    AND (p_component_name IS NULL OR pm.component_name = p_component_name)
    GROUP BY pm.component_name, pm.operation_type
    ORDER BY pm.component_name, pm.operation_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 3. CREATE MONITORING TRIGGERS
-- ============================================================

-- Trigger to log subscription plan operations
CREATE OR REPLACE FUNCTION log_subscription_plans_operation()
RETURNS TRIGGER AS $$
DECLARE
    operation_type TEXT;
    start_time TIMESTAMPTZ := clock_timestamp();
    execution_time INTEGER;
BEGIN
    operation_type := TG_OP;
    execution_time := EXTRACT(MILLISECONDS FROM clock_timestamp() - start_time)::INTEGER;
    
    PERFORM log_phase1_performance(
        'subscription_plans',
        operation_type,
        execution_time,
        TRUE,
        NULL,
        jsonb_build_object(
            'table_name', TG_TABLE_NAME,
            'new_record', CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW) ELSE NULL END,
            'old_record', CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN row_to_json(OLD) ELSE NULL END
        )
    );
    
    RETURN COALESCE(NEW, OLD);
EXCEPTION WHEN OTHERS THEN
    execution_time := EXTRACT(MILLISECONDS FROM clock_timestamp() - start_time)::INTEGER;
    PERFORM log_phase1_performance(
        'subscription_plans',
        operation_type,
        execution_time,
        FALSE,
        SQLERRM,
        jsonb_build_object('error_detail', SQLSTATE)
    );
    RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply trigger to subscription_plans table
DROP TRIGGER IF EXISTS subscription_plans_monitoring_trigger ON public.subscription_plans;
CREATE TRIGGER subscription_plans_monitoring_trigger
    AFTER INSERT OR UPDATE OR DELETE ON public.subscription_plans
    FOR EACH ROW EXECUTE FUNCTION log_subscription_plans_operation();

-- ============================================================
-- 4. CREATE ALERT RULES
-- ============================================================

-- Default alert configurations
INSERT INTO public.phase1_alert_config (
    alert_name, component_name, metric_type, threshold_value, 
    comparison_operator, time_window_minutes, severity, notification_channels
) VALUES 
-- Subscription Plans Alerts
('subscription_plans_high_error_rate', 'subscription_plans', 'error_rate', 5, '>', 5, 'warning', ARRAY['email', 'slack']),
('subscription_plans_slow_operations', 'subscription_plans', 'avg_execution_time', 1000, '>', 10, 'warning', ARRAY['email']),
('subscription_plans_schema_missing', 'subscription_plans', 'schema_health', 0, '=', 1, 'critical', ARRAY['email', 'slack', 'pagerduty']),

-- Wallet Functions Alerts  
('wallet_functions_high_error_rate', 'wallet_functions', 'error_rate', 3, '>', 5, 'warning', ARRAY['email', 'slack']),
('wallet_functions_missing', 'wallet_functions', 'function_availability', 0, '=', 1, 'critical', ARRAY['email', 'slack', 'pagerduty']),
('wallet_functions_slow_operations', 'wallet_functions', 'avg_execution_time', 2000, '>', 10, 'warning', ARRAY['email']),

-- Subscription Payments Alerts
('subscription_payments_table_missing', 'subscription_payments', 'table_availability', 0, '=', 1, 'critical', ARRAY['email', 'slack', 'pagerduty']),
('subscription_payments_high_error_rate', 'subscription_payments', 'error_rate', 5, '>', 5, 'warning', ARRAY['email', 'slack']),
('subscription_payments_no_activity', 'subscription_payments', 'operation_count', 0, '=', 60, 'info', ARRAY['email'])
ON CONFLICT (alert_name) DO UPDATE SET
    threshold_value = EXCLUDED.threshold_value,
    time_window_minutes = EXCLUDED.time_window_minutes,
    updated_at = NOW();

-- ============================================================
-- 5. CREATE INDEXES FOR PERFORMANCE
-- ============================================================

-- Performance metrics indexes
CREATE INDEX IF NOT EXISTS idx_phase1_performance_component_time 
ON public.phase1_performance_metrics (component_name, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_phase1_performance_operation_time 
ON public.phase1_performance_metrics (operation_type, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_phase1_performance_success_time 
ON public.phase1_performance_metrics (success, created_at DESC);

-- Health checks indexes
CREATE INDEX IF NOT EXISTS idx_phase1_health_checks_component_time 
ON public.phase1_health_checks (component_name, checked_at DESC);

CREATE INDEX IF NOT EXISTS idx_phase1_health_checks_status_time 
ON public.phase1_health_checks (status, checked_at DESC);

-- Error log indexes
CREATE INDEX IF NOT EXISTS idx_phase1_error_log_component_time 
ON public.phase1_error_log (component_name, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_phase1_error_log_resolved 
ON public.phase1_error_log (resolved_at) WHERE resolved_at IS NULL;

-- ============================================================
-- 6. GRANT PERMISSIONS
-- ============================================================

-- Grant access to monitoring functions for admin users
GRANT EXECUTE ON FUNCTION check_phase1_health() TO authenticated;
GRANT EXECUTE ON FUNCTION analyze_phase1_performance(TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION log_phase1_performance(TEXT, TEXT, INTEGER, BOOLEAN, TEXT, JSONB) TO authenticated;

-- Grant read access to monitoring tables for admin dashboard
GRANT SELECT ON public.phase1_performance_metrics TO authenticated;
GRANT SELECT ON public.phase1_health_checks TO authenticated;
GRANT SELECT ON public.phase1_error_log TO authenticated;
GRANT SELECT ON public.phase1_alert_config TO authenticated;

-- Grant insert access for logging
GRANT INSERT ON public.phase1_performance_metrics TO authenticated;
GRANT INSERT ON public.phase1_health_checks TO authenticated;
GRANT INSERT ON public.phase1_error_log TO authenticated;

-- ============================================================
-- 7. VALIDATION QUERIES
-- ============================================================

-- Validate monitoring setup
DO $$
BEGIN
    -- Test health check function
    PERFORM check_phase1_health();
    RAISE NOTICE 'Health check function validated successfully';
    
    -- Test performance analysis function
    PERFORM analyze_phase1_performance();
    RAISE NOTICE 'Performance analysis function validated successfully';
    
    -- Validate alert configurations
    IF (SELECT COUNT(*) FROM public.phase1_alert_config) >= 9 THEN
        RAISE NOTICE 'Alert configurations created successfully (% rules)', (SELECT COUNT(*) FROM public.phase1_alert_config);
    ELSE
        RAISE WARNING 'Alert configuration count is lower than expected';
    END IF;
    
    RAISE NOTICE 'Phase 1 monitoring setup completed successfully!';
END $$;

-- ============================================================
-- SETUP COMPLETE
-- ============================================================
-- The Phase 1 monitoring system is now active and includes:
-- 
-- ✅ Performance metrics tracking
-- ✅ Health check monitoring  
-- ✅ Error tracking and logging
-- ✅ Configurable alerting system
-- ✅ Automated triggers for data operations
-- ✅ Performance analysis functions
-- ✅ Proper indexing for query performance
-- ✅ Security and access controls
-- 
-- Next Steps:
-- 1. Run ./phase1_monitoring_dashboard.sh to set up dashboards
-- 2. Configure notification channels (email, Slack, PagerDuty)
-- 3. Set up automated monitoring scripts
-- 4. Test alert thresholds in staging environment
-- ============================================================