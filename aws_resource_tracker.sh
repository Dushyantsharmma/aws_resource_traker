#!/bin/bash

###############################################################################
# AWS Resource Tracker Script
# 
# Description: Automates AWS resource usage tracking for S3, EC2, Lambda, 
#              and IAM Users. Generates daily reports with timestamped logs.
#
# Author: AWS Resource Tracker
# Version: 1.0
###############################################################################

# Set strict error handling
set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
LOG_FILE="${LOG_DIR}/aws_resource_report_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create logs directory if it doesn't exist
mkdir -p "${LOG_DIR}"

###############################################################################
# Logging Functions
###############################################################################

log_info() {
    local message="$1"
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

log_warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

log_header() {
    local header="$1"
    echo -e "\n${BLUE}================================================${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE} $header${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}================================================${NC}" | tee -a "$LOG_FILE"
}

###############################################################################
# AWS Resource Tracking Functions
###############################################################################

check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found. Please install AWS CLI and configure credentials."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    log_info "AWS CLI is configured and accessible"
}

track_s3_resources() {
    log_header "S3 BUCKET TRACKING"
    
    log_info "Fetching S3 bucket information..."
    
    # Get total number of buckets
    local bucket_count
    bucket_count=$(aws s3api list-buckets --query 'Buckets[].Name' --output text | wc -w)
    log_info "Total S3 buckets: $bucket_count"
    
    if [ "$bucket_count" -gt 0 ]; then
        echo -e "\nS3 Buckets:" | tee -a "$LOG_FILE"
        echo "============" | tee -a "$LOG_FILE"
        
        # List all buckets with details
        aws s3api list-buckets --query 'Buckets[].[Name,CreationDate]' --output table | tee -a "$LOG_FILE"
        
        # Get bucket sizes (this might take time for many buckets)
        log_info "Calculating bucket sizes..."
        while IFS= read -r bucket; do
            if [ -n "$bucket" ]; then
                local size
                size=$(aws s3 ls "s3://$bucket" --recursive --summarize 2>/dev/null | grep "Total Size:" | awk '{print $3}' || echo "0")
                log_info "Bucket: $bucket, Size: $size bytes"
            fi
        done < <(aws s3api list-buckets --query 'Buckets[].Name' --output text | tr '\t' '\n')
    else
        log_warn "No S3 buckets found"
    fi
}

track_ec2_resources() {
    log_header "EC2 INSTANCE TRACKING"
    
    log_info "Fetching EC2 instance information..."
    
    # Get total number of instances
    local instance_count
    instance_count=$(aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text | wc -w)
    log_info "Total EC2 instances: $instance_count"
    
    if [ "$instance_count" -gt 0 ]; then
        echo -e "\nEC2 Instances:" | tee -a "$LOG_FILE"
        echo "==============" | tee -a "$LOG_FILE"
        
        # List instances with details
        aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name,LaunchTime,Tags[?Key==`Name`].Value|[0]]' --output table | tee -a "$LOG_FILE"
        
        # Count by state
        local running_count stopped_count terminated_count
        running_count=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId' --output text | wc -w)
        stopped_count=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=stopped" --query 'Reservations[].Instances[].InstanceId' --output text | wc -w)
        terminated_count=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=terminated" --query 'Reservations[].Instances[].InstanceId' --output text | wc -w)
        
        log_info "Running instances: $running_count"
        log_info "Stopped instances: $stopped_count"
        log_info "Terminated instances: $terminated_count"
    else
        log_warn "No EC2 instances found"
    fi
}

track_lambda_resources() {
    log_header "LAMBDA FUNCTION TRACKING"
    
    log_info "Fetching Lambda function information..."
    
    # Get total number of functions
    local function_count
    function_count=$(aws lambda list-functions --query 'Functions[].FunctionName' --output text | wc -w)
    log_info "Total Lambda functions: $function_count"
    
    if [ "$function_count" -gt 0 ]; then
        echo -e "\nLambda Functions:" | tee -a "$LOG_FILE"
        echo "=================" | tee -a "$LOG_FILE"
        
        # List functions with details
        aws lambda list-functions --query 'Functions[].[FunctionName,Runtime,LastModified,CodeSize,Timeout]' --output table | tee -a "$LOG_FILE"
        
        # Calculate total code size
        local total_size
        total_size=$(aws lambda list-functions --query 'sum(Functions[].CodeSize)' --output text)
        log_info "Total Lambda code size: $total_size bytes"
    else
        log_warn "No Lambda functions found"
    fi
}

track_iam_resources() {
    log_header "IAM USER TRACKING"
    
    log_info "Fetching IAM user information..."
    
    # Get total number of users
    local user_count
    user_count=$(aws iam list-users --query 'Users[].UserName' --output text | wc -w)
    log_info "Total IAM users: $user_count"
    
    if [ "$user_count" -gt 0 ]; then
        echo -e "\nIAM Users:" | tee -a "$LOG_FILE"
        echo "==========" | tee -a "$LOG_FILE"
        
        # List users with details
        aws iam list-users --query 'Users[].[UserName,CreateDate,PasswordLastUsed]' --output table | tee -a "$LOG_FILE"
        
        # Count users with console access
        local console_users=0
        while IFS= read -r user; do
            if [ -n "$user" ]; then
                if aws iam get-login-profile --user-name "$user" &>/dev/null; then
                    ((console_users++))
                fi
            fi
        done < <(aws iam list-users --query 'Users[].UserName' --output text | tr '\t' '\n')
        
        log_info "Users with console access: $console_users"
    else
        log_warn "No IAM users found"
    fi
}

generate_summary() {
    log_header "RESOURCE SUMMARY"
    
    local s3_count ec2_count lambda_count iam_count
    s3_count=$(aws s3api list-buckets --query 'Buckets[].Name' --output text | wc -w)
    ec2_count=$(aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text | wc -w)
    lambda_count=$(aws lambda list-functions --query 'Functions[].FunctionName' --output text | wc -w)
    iam_count=$(aws iam list-users --query 'Users[].UserName' --output text | wc -w)
    
    echo -e "\nRESOURCE SUMMARY:" | tee -a "$LOG_FILE"
    echo "=================" | tee -a "$LOG_FILE"
    echo "S3 Buckets: $s3_count" | tee -a "$LOG_FILE"
    echo "EC2 Instances: $ec2_count" | tee -a "$LOG_FILE"
    echo "Lambda Functions: $lambda_count" | tee -a "$LOG_FILE"
    echo "IAM Users: $iam_count" | tee -a "$LOG_FILE"
    echo "Report generated: $(date)" | tee -a "$LOG_FILE"
    echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
}

###############################################################################
# Main Execution
###############################################################################

main() {
    log_info "Starting AWS Resource Tracker - $(date)"
    log_info "Log file: $LOG_FILE"
    
    # Check prerequisites
    check_aws_cli
    
    # Track all resources
    track_s3_resources
    track_ec2_resources
    track_lambda_resources
    track_iam_resources
    
    # Generate summary
    generate_summary
    
    log_info "AWS Resource Tracking completed successfully"
    echo -e "\n${GREEN}Report saved to: $LOG_FILE${NC}"
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi