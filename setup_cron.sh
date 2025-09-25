#!/bin/bash

###############################################################################
# Cron Setup Script for AWS Resource Tracker
# 
# Description: Sets up cron job to run AWS resource tracker daily at 6:30 PM
#
# Author: AWS Resource Tracker
# Version: 1.0
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRACKER_SCRIPT="${SCRIPT_DIR}/aws_resource_tracker.sh"
CRON_SCHEDULE="30 18 * * *"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if cron is installed
    if ! command -v crontab &> /dev/null; then
        log_error "crontab command not found. Please install cron package."
        exit 1
    fi
    
    # Check if the tracker script exists and is executable
    if [ ! -f "$TRACKER_SCRIPT" ]; then
        log_error "AWS resource tracker script not found at: $TRACKER_SCRIPT"
        exit 1
    fi
    
    if [ ! -x "$TRACKER_SCRIPT" ]; then
        log_warn "Making tracker script executable..."
        chmod +x "$TRACKER_SCRIPT"
    fi
    
    log_info "Prerequisites check completed"
}

setup_cron_job() {
    log_info "Setting up cron job..."
    
    # Create a temporary cron file
    local temp_cron=$(mktemp)
    
    # Get existing cron jobs (if any)
    crontab -l > "$temp_cron" 2>/dev/null || true
    
    # Check if our job already exists
    if grep -q "aws_resource_tracker.sh" "$temp_cron"; then
        log_warn "Cron job for AWS resource tracker already exists. Updating..."
        # Remove existing job
        grep -v "aws_resource_tracker.sh" "$temp_cron" > "${temp_cron}.new" || true
        mv "${temp_cron}.new" "$temp_cron"
    fi
    
    # Add our cron job
    echo "# AWS Resource Tracker - Daily report at 6:30 PM" >> "$temp_cron"
    echo "$CRON_SCHEDULE $TRACKER_SCRIPT >> ${SCRIPT_DIR}/logs/cron.log 2>&1" >> "$temp_cron"
    
    # Install the new cron jobs
    crontab "$temp_cron"
    
    # Clean up
    rm "$temp_cron"
    
    log_info "Cron job installed successfully"
    log_info "Schedule: Daily at 6:30 PM"
    log_info "Command: $TRACKER_SCRIPT"
    log_info "Logs: ${SCRIPT_DIR}/logs/cron.log"
}

show_cron_status() {
    log_info "Current cron jobs:"
    echo "=================="
    crontab -l 2>/dev/null || log_warn "No cron jobs found"
    echo
}

create_log_directory() {
    local log_dir="${SCRIPT_DIR}/logs"
    if [ ! -d "$log_dir" ]; then
        log_info "Creating logs directory: $log_dir"
        mkdir -p "$log_dir"
    fi
}

main() {
    echo "AWS Resource Tracker - Cron Setup"
    echo "=================================="
    echo
    
    check_prerequisites
    create_log_directory
    setup_cron_job
    show_cron_status
    
    echo
    log_info "Setup completed successfully!"
    log_info "The AWS resource tracker will run daily at 6:30 PM"
    log_info "To manually run the tracker: $TRACKER_SCRIPT"
    log_info "To view scheduled jobs: crontab -l"
    log_info "To remove the job: crontab -e (then delete the line)"
    echo
}

# Handle script interruption
trap 'log_error "Setup interrupted"; exit 1' INT TERM

# Show usage if help requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Usage: $0 [--help]"
    echo
    echo "This script sets up a cron job to run the AWS resource tracker"
    echo "daily at 6:30 PM. The tracker generates timestamped reports"
    echo "of AWS resource usage (S3, EC2, Lambda, IAM Users)."
    echo
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo
    exit 0
fi

# Run main function
main "$@"