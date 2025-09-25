#!/bin/bash

###############################################################################
# Log Cleanup Script for AWS Resource Tracker
# 
# Description: Cleans up old log files to prevent disk space issues
#
# Author: AWS Resource Tracker
# Version: 1.0
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
DEFAULT_RETENTION_DAYS=30
DEFAULT_MAX_FILES=50

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Clean up old AWS resource tracker log files.

Options:
    -d, --days DAYS       Keep logs newer than DAYS (default: 30)
    -f, --max-files NUM   Keep at most NUM newest files (default: 50)
    -n, --dry-run         Show what would be deleted without actually deleting
    -h, --help            Show this help message

Examples:
    $0                    # Use default settings (30 days, 50 files max)
    $0 -d 7               # Keep only logs from last 7 days
    $0 -f 20              # Keep only newest 20 log files
    $0 -n                 # Dry run - show what would be deleted
EOF
}

cleanup_by_age() {
    local retention_days=$1
    local dry_run=$2
    
    log_info "Cleaning up log files older than $retention_days days..."
    
    if [ ! -d "$LOG_DIR" ]; then
        log_warn "Log directory does not exist: $LOG_DIR"
        return
    fi
    
    local files_found
    files_found=$(find "$LOG_DIR" -name "aws_resource_report_*.log" -type f -mtime +$retention_days | wc -l)
    
    if [ "$files_found" -eq 0 ]; then
        log_info "No log files older than $retention_days days found"
        return
    fi
    
    log_info "Found $files_found log files older than $retention_days days"
    
    if [ "$dry_run" = true ]; then
        log_info "DRY RUN - Files that would be deleted:"
        find "$LOG_DIR" -name "aws_resource_report_*.log" -type f -mtime +$retention_days -printf "%p (modified: %t)\n"
    else
        find "$LOG_DIR" -name "aws_resource_report_*.log" -type f -mtime +$retention_days -delete
        log_info "Deleted $files_found old log files"
    fi
}

cleanup_by_count() {
    local max_files=$1
    local dry_run=$2
    
    log_info "Keeping only the newest $max_files log files..."
    
    if [ ! -d "$LOG_DIR" ]; then
        log_warn "Log directory does not exist: $LOG_DIR"
        return
    fi
    
    local total_files
    total_files=$(find "$LOG_DIR" -name "aws_resource_report_*.log" -type f | wc -l)
    
    if [ "$total_files" -le "$max_files" ]; then
        log_info "Current log file count ($total_files) is within limit ($max_files)"
        return
    fi
    
    local files_to_delete=$((total_files - max_files))
    log_info "Found $total_files log files, need to delete $files_to_delete oldest files"
    
    if [ "$dry_run" = true ]; then
        log_info "DRY RUN - Files that would be deleted:"
        find "$LOG_DIR" -name "aws_resource_report_*.log" -type f -printf "%p %T@\n" | \
            sort -k2 -n | head -n "$files_to_delete" | cut -d' ' -f1 | \
            while read -r file; do
                echo "  $file (modified: $(stat -c %y "$file"))"
            done
    else
        find "$LOG_DIR" -name "aws_resource_report_*.log" -type f -printf "%p %T@\n" | \
            sort -k2 -n | head -n "$files_to_delete" | cut -d' ' -f1 | \
            xargs rm -f
        log_info "Deleted $files_to_delete old log files"
    fi
}

show_log_stats() {
    if [ ! -d "$LOG_DIR" ]; then
        log_warn "Log directory does not exist: $LOG_DIR"
        return
    fi
    
    local total_files total_size oldest_file newest_file
    total_files=$(find "$LOG_DIR" -name "aws_resource_report_*.log" -type f | wc -l)
    
    if [ "$total_files" -eq 0 ]; then
        log_info "No log files found in $LOG_DIR"
        return
    fi
    
    total_size=$(du -sh "$LOG_DIR" | cut -f1)
    oldest_file=$(find "$LOG_DIR" -name "aws_resource_report_*.log" -type f -printf "%p %T@\n" | sort -k2 -n | head -n1 | cut -d' ' -f1)
    newest_file=$(find "$LOG_DIR" -name "aws_resource_report_*.log" -type f -printf "%p %T@\n" | sort -k2 -nr | head -n1 | cut -d' ' -f1)
    
    echo
    log_info "Log Statistics:"
    echo "==============="
    echo "Total log files: $total_files"
    echo "Total directory size: $total_size"
    echo "Oldest log: $(basename "$oldest_file") ($(stat -c %y "$oldest_file"))"
    echo "Newest log: $(basename "$newest_file") ($(stat -c %y "$newest_file"))"
}

main() {
    local retention_days=$DEFAULT_RETENTION_DAYS
    local max_files=$DEFAULT_MAX_FILES
    local dry_run=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--days)
                retention_days="$2"
                shift 2
                ;;
            -f|--max-files)
                max_files="$2"
                shift 2
                ;;
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Validate arguments
    if ! [[ "$retention_days" =~ ^[0-9]+$ ]] || [ "$retention_days" -lt 1 ]; then
        log_error "Invalid retention days: $retention_days (must be positive integer)"
        exit 1
    fi
    
    if ! [[ "$max_files" =~ ^[0-9]+$ ]] || [ "$max_files" -lt 1 ]; then
        log_error "Invalid max files: $max_files (must be positive integer)"
        exit 1
    fi
    
    log_info "Starting log cleanup..."
    if [ "$dry_run" = true ]; then
        log_warn "DRY RUN MODE - No files will actually be deleted"
    fi
    
    show_log_stats
    
    # Clean up by age first, then by count
    cleanup_by_age "$retention_days" "$dry_run"
    cleanup_by_count "$max_files" "$dry_run"
    
    if [ "$dry_run" = false ]; then
        show_log_stats
    fi
    
    log_info "Log cleanup completed"
}

# Handle script interruption
trap 'log_error "Cleanup interrupted"; exit 1' INT TERM

# Run main function
main "$@"