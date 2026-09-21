#!/bin/bash
# ============================================================
# Phase 1 Critical Database Fixes - Monitoring Dashboard
# ============================================================
# This script provides a comprehensive monitoring dashboard for
# the three Phase 1 fixes with real-time health status,
# performance metrics, and alerting capabilities.
# ============================================================

set -e

# Configuration
DATABASE_URL=${DATABASE_URL:-"postgresql://localhost:5432/rexo_marketplace"}
LOG_FILE="./phase1_monitoring_$(date +%Y%m%d_%H%M%S).log"
ALERT_THRESHOLD_ERROR_RATE=5
ALERT_THRESHOLD_SLOW_OPERATION=1000

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Print header
print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}       Phase 1 Database Fixes - Monitoring Dashboard      ${NC}"
    echo -e "${BLUE}============================================================${NC}"
    echo -e "Monitoring Session: $(date)"
    echo -e "Database: $DATABASE_URL"
    echo -e "Log File: $LOG_FILE"
    echo ""
}

# Health status check
check_health_status() {
    echo -e "${CYAN}🏥 HEALTH STATUS CHECK${NC}"
    echo "----------------------------------------"
    
    local health_results=$(psql "$DATABASE_URL" -t -c "SELECT component, status, details FROM check_phase1_health() ORDER BY component;")
    
    while IFS='|' read -r component status details; do
        component=$(echo "$component" | xargs)
        status=$(echo "$status" | xargs)
        details=$(echo "$details" | xargs)
        
        case $status in
            "healthy")
                echo -e "✅ ${GREEN}$component${NC}: $status"
                ;;
            "warning")
                echo -e "⚠️  ${YELLOW}$component${NC}: $status"
                ;;
            "critical")
                echo -e "❌ ${RED}$component${NC}: $status"
                log "ALERT: Critical status for $component - $details"
                ;;
        esac
        
        # Parse and display key details
        if [[ $component == "subscription_plans" ]]; then
            interval_exists=$(echo "$details" | jq -r '.interval_column_exists // false')
            total_plans=$(echo "$details" | jq -r '.total_plans // 0')
            echo "   📊 Interval Column: $interval_exists | Total Plans: $total_plans"
        elif [[ $component == "wallet_functions" ]]; then
            credit_exists=$(echo "$details" | jq -r '.credit_wallet_exists // false')
            debit_exists=$(echo "$details" | jq -r '.debit_wallet_exists // false')
            echo "   🔧 Credit Function: $credit_exists | Debit Function: $debit_exists"
        elif [[ $component == "subscription_payments" ]]; then
            table_exists=$(echo "$details" | jq -r '.table_exists // false')
            total_payments=$(echo "$details" | jq -r '.total_payments // "N/A"')
            echo "   💳 Table Exists: $table_exists | Total Payments: $total_payments"
        fi
    done <<< "$health_results"
    
    echo ""
}

# Performance metrics analysis
analyze_performance() {
    echo -e "${PURPLE}⚡ PERFORMANCE ANALYSIS${NC}"
    echo "----------------------------------------"
    
    local perf_results=$(psql "$DATABASE_URL" -t -c "SELECT * FROM analyze_phase1_performance(NULL, 24) ORDER BY component, operation_type;")
    
    if [[ -z "$perf_results" ]]; then
        echo -e "${YELLOW}No performance data available for the last 24 hours${NC}"
        echo ""
        return
    fi
    
    printf "%-20s %-15s %-8s %-12s %-12s %-8s %-8s\n" "Component" "Operation" "Total" "Success%" "Avg Time" "Max Time" "Errors"
    echo "--------------------------------------------------------------------------------------------"
    
    while IFS='|' read -r component operation total success_rate avg_time max_time errors; do
        component=$(echo "$component" | xargs)
        operation=$(echo "$operation" | xargs)
        total=$(echo "$total" | xargs)
        success_rate=$(echo "$success_rate" | xargs)
        avg_time=$(echo "$avg_time" | xargs)
        max_time=$(echo "$max_time" | xargs)
        errors=$(echo "$errors" | xargs)
        
        # Color coding based on performance
        if (( $(echo "$success_rate < 95" | bc -l) )); then
            color=$RED
        elif (( $(echo "$avg_time > $ALERT_THRESHOLD_SLOW_OPERATION" | bc -l) )); then
            color=$YELLOW
        else
            color=$GREEN
        fi
        
        printf "${color}%-20s %-15s %-8s %-12s %-12s %-8s %-8s${NC}\n" \
            "$component" "$operation" "$total" "$success_rate%" "${avg_time}ms" "${max_time}ms" "$errors"
        
        # Alert on high error rate
        if (( $(echo "$success_rate < 95" | bc -l) )); then
            log "ALERT: High error rate for $component.$operation: $success_rate%"
        fi
        
        # Alert on slow operations
        if (( $(echo "$avg_time > $ALERT_THRESHOLD_SLOW_OPERATION" | bc -l) )); then
            log "ALERT: Slow operations for $component.$operation: ${avg_time}ms average"
        fi
        
    done <<< "$perf_results"
    
    echo ""
}

# Recent errors analysis
check_recent_errors() {
    echo -e "${RED}🚨 RECENT ERRORS (Last 4 Hours)${NC}"
    echo "----------------------------------------"
    
    local error_results=$(psql "$DATABASE_URL" -t -c "
        SELECT 
            component_name,
            error_type,
            COUNT(*) as error_count,
            MAX(created_at) as latest_error
        FROM phase1_error_log 
        WHERE created_at > NOW() - INTERVAL '4 hours'
        AND resolved_at IS NULL
        GROUP BY component_name, error_type
        ORDER BY error_count DESC, latest_error DESC
        LIMIT 10;
    ")
    
    if [[ -z "$error_results" ]]; then
        echo -e "${GREEN}✅ No unresolved errors in the last 4 hours${NC}"
        echo ""
        return
    fi
    
    printf "%-20s %-25s %-8s %-20s\n" "Component" "Error Type" "Count" "Latest"
    echo "-----------------------------------------------------------------------"
    
    while IFS='|' read -r component error_type count latest; do
        component=$(echo "$component" | xargs)
        error_type=$(echo "$error_type" | xargs)
        count=$(echo "$count" | xargs)
        latest=$(echo "$latest" | xargs)
        
        printf "${RED}%-20s %-25s %-8s %-20s${NC}\n" "$component" "$error_type" "$count" "$latest"
        log "ERROR: $component - $error_type (Count: $count, Latest: $latest)"
    done <<< "$error_results"
    
    echo ""
}

# Database connection and migration status
check_database_status() {
    echo -e "${BLUE}🔗 DATABASE STATUS${NC}"
    echo "----------------------------------------"
    
    # Check database connectivity
    if psql "$DATABASE_URL" -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "✅ ${GREEN}Database Connection: Active${NC}"
    else
        echo -e "❌ ${RED}Database Connection: Failed${NC}"
        log "CRITICAL: Database connection failed"
        return 1
    fi
    
    # Check migration status
    local migration_status=$(psql "$DATABASE_URL" -t -c "
        SELECT 
            CASE WHEN EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='subscription_plans' AND column_name='interval')
                 THEN 'Applied' ELSE 'Missing' END as migration_1,
            CASE WHEN EXISTS(SELECT 1 FROM pg_proc WHERE proname='credit_wallet')
                 THEN 'Applied' ELSE 'Missing' END as migration_2,
            CASE WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name='subscription_payments')
                 THEN 'Applied' ELSE 'Missing' END as migration_3;
    ")
    
    IFS='|' read -r migration_1 migration_2 migration_3 <<< "$migration_status"
    migration_1=$(echo "$migration_1" | xargs)
    migration_2=$(echo "$migration_2" | xargs)
    migration_3=$(echo "$migration_3" | xargs)
    
    echo "📋 Migration Status:"
    echo "   Migration 1 (Subscription Plans): $migration_1"
    echo "   Migration 2 (Wallet Functions): $migration_2"
    echo "   Migration 3 (Subscription Payments): $migration_3"
    
    echo ""
}

# Alert configuration status
check_alert_configuration() {
    echo -e "${YELLOW}🔔 ALERT CONFIGURATION${NC}"
    echo "----------------------------------------"
    
    local alert_config=$(psql "$DATABASE_URL" -t -c "
        SELECT 
            COUNT(*) as total_alerts,
            COUNT(*) FILTER (WHERE enabled = true) as enabled_alerts,
            COUNT(*) FILTER (WHERE severity = 'critical') as critical_alerts,
            COUNT(*) FILTER (WHERE severity = 'warning') as warning_alerts
        FROM phase1_alert_config;
    ")
    
    IFS='|' read -r total enabled critical warning <<< "$alert_config"
    total=$(echo "$total" | xargs)
    enabled=$(echo "$enabled" | xargs)
    critical=$(echo "$critical" | xargs)
    warning=$(echo "$warning" | xargs)
    
    echo "📊 Alert Rules:"
    echo "   Total Configured: $total"
    echo "   Currently Enabled: $enabled"
    echo "   Critical Alerts: $critical"
    echo "   Warning Alerts: $warning"
    
    # Show recent alert triggers (if any)
    local recent_alerts=$(psql "$DATABASE_URL" -t -c "
        SELECT COUNT(*) FROM phase1_health_checks 
        WHERE checked_at > NOW() - INTERVAL '1 hour' 
        AND status IN ('warning', 'critical');
    ")
    
    recent_alerts=$(echo "$recent_alerts" | xargs)
    echo "   Recent Triggers (1h): $recent_alerts"
    
    echo ""
}

# System resource usage
check_system_resources() {
    echo -e "${CYAN}💻 SYSTEM RESOURCES${NC}"
    echo "----------------------------------------"
    
    # Database size and connections
    local db_stats=$(psql "$DATABASE_URL" -t -c "
        SELECT 
            pg_size_pretty(pg_database_size(current_database())) as db_size,
            (SELECT COUNT(*) FROM pg_stat_activity WHERE state = 'active') as active_connections,
            (SELECT COUNT(*) FROM pg_stat_activity) as total_connections;
    ")
    
    IFS='|' read -r db_size active_conn total_conn <<< "$db_stats"
    db_size=$(echo "$db_size" | xargs)
    active_conn=$(echo "$active_conn" | xargs)
    total_conn=$(echo "$total_conn" | xargs)
    
    echo "💾 Database Metrics:"
    echo "   Database Size: $db_size"
    echo "   Active Connections: $active_conn"
    echo "   Total Connections: $total_conn"
    
    # Phase 1 table sizes
    local table_sizes=$(psql "$DATABASE_URL" -t -c "
        SELECT 
            schemaname,
            tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
        FROM pg_tables 
        WHERE tablename IN ('subscription_plans', 'subscription_payments', 'phase1_performance_metrics', 'phase1_health_checks')
        AND schemaname = 'public'
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
    ")
    
    echo "📊 Phase 1 Table Sizes:"
    while IFS='|' read -r schema table size; do
        schema=$(echo "$schema" | xargs)
        table=$(echo "$table" | xargs)
        size=$(echo "$size" | xargs)
        echo "   $table: $size"
    done <<< "$table_sizes"
    
    echo ""
}

# Generate monitoring report
generate_report() {
    echo -e "${GREEN}📋 MONITORING REPORT${NC}"
    echo "----------------------------------------"
    
    local report_file="phase1_monitoring_report_$(date +%Y%m%d_%H%M%S).json"
    
    psql "$DATABASE_URL" -t -c "
        WITH health_summary AS (
            SELECT json_agg(
                json_build_object(
                    'component', component,
                    'status', status,
                    'details', details
                )
            ) as health_data
            FROM check_phase1_health()
        ),
        performance_summary AS (
            SELECT json_agg(
                json_build_object(
                    'component', component,
                    'operation_type', operation_type,
                    'total_operations', total_operations,
                    'success_rate', success_rate,
                    'avg_execution_time', avg_execution_time,
                    'error_count', error_count
                )
            ) as performance_data
            FROM analyze_phase1_performance(NULL, 24)
        ),
        error_summary AS (
            SELECT json_agg(
                json_build_object(
                    'component', component_name,
                    'error_type', error_type,
                    'error_count', COUNT(*),
                    'latest_error', MAX(created_at)
                )
            ) as error_data
            FROM phase1_error_log 
            WHERE created_at > NOW() - INTERVAL '24 hours'
            GROUP BY component_name, error_type
        )
        SELECT json_build_object(
            'timestamp', NOW(),
            'report_type', 'phase1_monitoring_summary',
            'health_status', health_summary.health_data,
            'performance_metrics', performance_summary.performance_data,
            'error_analysis', error_summary.error_data,
            'database_url', '$DATABASE_URL'
        )
        FROM health_summary, performance_summary, error_summary;
    " > "$report_file"
    
    echo "📄 Detailed report saved to: $report_file"
    echo "📊 Log file available at: $LOG_FILE"
    
    # Show summary stats
    local total_checks=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
    local alerts_count=$(grep -c "ALERT:" "$LOG_FILE" 2>/dev/null || echo "0")
    local errors_count=$(grep -c "ERROR:" "$LOG_FILE" 2>/dev/null || echo "0")
    
    echo "📈 Session Summary:"
    echo "   Total Log Entries: $total_checks"
    echo "   Alerts Generated: $alerts_count"
    echo "   Errors Detected: $errors_count"
    
    echo ""
}

# Interactive monitoring mode
interactive_monitoring() {
    echo -e "${GREEN}🔄 INTERACTIVE MONITORING MODE${NC}"
    echo "Press Ctrl+C to exit"
    echo ""
    
    while true; do
        clear
        print_header
        check_health_status
        analyze_performance
        check_recent_errors
        
        echo -e "${BLUE}Next refresh in 30 seconds...${NC}"
        sleep 30
    done
}

# Main execution
main() {
    case "${1:-dashboard}" in
        "dashboard")
            print_header
            check_database_status
            check_health_status
            analyze_performance
            check_recent_errors
            check_alert_configuration
            check_system_resources
            generate_report
            ;;
        "interactive")
            interactive_monitoring
            ;;
        "health")
            check_health_status
            ;;
        "performance")
            analyze_performance
            ;;
        "errors")
            check_recent_errors
            ;;
        "report")
            generate_report
            ;;
        "help"|"--help"|"-h")
            echo "Phase 1 Monitoring Dashboard"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  dashboard     Full monitoring dashboard (default)"
            echo "  interactive   Interactive real-time monitoring"
            echo "  health        Health status check only"
            echo "  performance   Performance analysis only"
            echo "  errors        Recent errors analysis only"
            echo "  report        Generate detailed JSON report"
            echo "  help          Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  DATABASE_URL  PostgreSQL connection string"
            echo ""
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Error handling
trap 'echo -e "\n${RED}Monitoring interrupted${NC}"; exit 130' INT
trap 'echo -e "\n${RED}Monitoring error occurred${NC}"; exit 1' ERR

# Execute main function
main "$@"

echo -e "${GREEN}✅ Monitoring session completed${NC}"