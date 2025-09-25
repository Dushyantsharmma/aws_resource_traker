#!/bin/bash

###############################################################################
# AWS Resource Tracker Demo Script
# 
# Description: Demonstrates the AWS Resource Tracker functionality
#              This script can be used for testing without affecting
#              actual cron jobs or requiring AWS credentials
#
# Author: AWS Resource Tracker
# Version: 1.0
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${BLUE} AWS Resource Tracker - Demo${NC}"
    echo -e "${BLUE}============================================${NC}\n"
}

print_section() {
    echo -e "\n${CYAN}--- $1 ---${NC}"
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check if main script exists
    if [ -f "${SCRIPT_DIR}/aws_resource_tracker.sh" ]; then
        echo -e "${GREEN}✓${NC} Main tracker script found"
    else
        echo -e "${RED}✗${NC} Main tracker script not found"
        return 1
    fi
    
    # Check if setup script exists
    if [ -f "${SCRIPT_DIR}/setup_cron.sh" ]; then
        echo -e "${GREEN}✓${NC} Cron setup script found"
    else
        echo -e "${RED}✗${NC} Cron setup script not found"
        return 1
    fi
    
    # Check if cleanup script exists
    if [ -f "${SCRIPT_DIR}/cleanup_logs.sh" ]; then
        echo -e "${GREEN}✓${NC} Log cleanup script found"
    else
        echo -e "${RED}✗${NC} Log cleanup script not found"
        return 1
    fi
    
    # Check if config file exists
    if [ -f "${SCRIPT_DIR}/config.conf" ]; then
        echo -e "${GREEN}✓${NC} Configuration file found"
    else
        echo -e "${RED}✗${NC} Configuration file not found"
        return 1
    fi
    
    # Check if scripts are executable
    for script in aws_resource_tracker.sh setup_cron.sh cleanup_logs.sh; do
        if [ -x "${SCRIPT_DIR}/$script" ]; then
            echo -e "${GREEN}✓${NC} $script is executable"
        else
            echo -e "${YELLOW}!${NC} $script is not executable (fixing...)"
            chmod +x "${SCRIPT_DIR}/$script"
            echo -e "${GREEN}✓${NC} $script made executable"
        fi
    done
    
    # Check for AWS CLI
    if command -v aws &> /dev/null; then
        echo -e "${GREEN}✓${NC} AWS CLI is installed"
        
        # Check AWS credentials
        if aws sts get-caller-identity &> /dev/null; then
            echo -e "${GREEN}✓${NC} AWS credentials are configured"
            local aws_user
            aws_user=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null || echo "Unknown")
            echo -e "  Current AWS identity: ${CYAN}$aws_user${NC}"
        else
            echo -e "${YELLOW}!${NC} AWS credentials not configured"
            echo -e "  Run 'aws configure' to set up credentials"
        fi
    else
        echo -e "${YELLOW}!${NC} AWS CLI not found"
        echo -e "  Install AWS CLI to use the tracker"
    fi
    
    # Check for cron
    if command -v crontab &> /dev/null; then
        echo -e "${GREEN}✓${NC} Cron is available"
    else
        echo -e "${YELLOW}!${NC} Cron not found"
        echo -e "  Install cron to enable automated scheduling"
    fi
}

show_file_structure() {
    print_section "File Structure"
    
    echo "aws_resource_traker/"
    echo "├── README.md                    # Documentation"
    echo "├── aws_resource_tracker.sh      # Main tracking script"
    echo "├── setup_cron.sh               # Cron job setup"
    echo "├── cleanup_logs.sh             # Log cleanup utility"
    echo "├── config.conf                 # Configuration"
    echo "├── demo.sh                     # This demo script"
    echo "├── .gitignore                  # Git ignore rules"
    echo "└── logs/                       # Log files (auto-created)"
    echo "    ├── aws_resource_report_*.log"
    echo "    └── cron.log"
}

show_usage_examples() {
    print_section "Usage Examples"
    
    echo -e "${CYAN}1. Run resource tracker manually:${NC}"
    echo "   ./aws_resource_tracker.sh"
    echo
    
    echo -e "${CYAN}2. Set up automated cron job:${NC}"
    echo "   ./setup_cron.sh"
    echo
    
    echo -e "${CYAN}3. View help for setup script:${NC}"
    echo "   ./setup_cron.sh --help"
    echo
    
    echo -e "${CYAN}4. Clean up old log files:${NC}"
    echo "   ./cleanup_logs.sh"
    echo "   ./cleanup_logs.sh --days 7"
    echo "   ./cleanup_logs.sh --max-files 20"
    echo "   ./cleanup_logs.sh --dry-run"
    echo
    
    echo -e "${CYAN}5. View current cron jobs:${NC}"
    echo "   crontab -l"
    echo
    
    echo -e "${CYAN}6. View log files:${NC}"
    echo "   ls -la logs/"
    echo "   cat logs/aws_resource_report_*.log"
}

simulate_output() {
    print_section "Sample Output Format"
    
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - Starting AWS Resource Tracker"
    echo
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} S3 BUCKET TRACKING${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - Total S3 buckets: 3"
    echo
    echo "S3 Buckets:"
    echo "============"
    echo "|        Name        |     CreationDate     |"
    echo "|--------------------|----------------------|"
    echo "|  my-app-logs       |  2024-01-15T10:30:00 |"
    echo "|  backup-storage    |  2024-02-01T14:20:00 |"
    echo "|  website-assets    |  2024-03-10T09:15:00 |"
    echo
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} RESOURCE SUMMARY${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
    echo "RESOURCE SUMMARY:"
    echo "=================="
    echo "S3 Buckets: 3"
    echo "EC2 Instances: 2"
    echo "Lambda Functions: 5"
    echo "IAM Users: 4"
    echo "Report generated: $(date)"
}

test_scripts() {
    print_section "Testing Script Functionality"
    
    # Test help functions
    echo -e "${CYAN}Testing help functions:${NC}"
    
    if ./setup_cron.sh --help &> /dev/null; then
        echo -e "${GREEN}✓${NC} setup_cron.sh --help works"
    else
        echo -e "${RED}✗${NC} setup_cron.sh --help failed"
    fi
    
    if ./cleanup_logs.sh --help &> /dev/null; then
        echo -e "${GREEN}✓${NC} cleanup_logs.sh --help works"
    else
        echo -e "${RED}✗${NC} cleanup_logs.sh --help failed"
    fi
    
    # Test dry run functionality
    echo -e "\n${CYAN}Testing dry-run functionality:${NC}"
    
    if ./cleanup_logs.sh --dry-run &> /dev/null; then
        echo -e "${GREEN}✓${NC} cleanup_logs.sh --dry-run works"
    else
        echo -e "${RED}✗${NC} cleanup_logs.sh --dry-run failed"
    fi
}

show_next_steps() {
    print_section "Next Steps"
    
    echo -e "${CYAN}To get started:${NC}"
    echo
    echo "1. Ensure AWS CLI is installed and configured:"
    echo "   aws configure"
    echo
    echo "2. Test the tracker manually:"
    echo "   ./aws_resource_tracker.sh"
    echo
    echo "3. Set up the automated cron job:"
    echo "   ./setup_cron.sh"
    echo
    echo "4. Check that everything is working:"
    echo "   crontab -l"
    echo "   ls -la logs/"
    echo
    echo -e "${CYAN}For more information:${NC}"
    echo "- Read the README.md file"
    echo "- Check the configuration in config.conf"
    echo "- Review the generated log files"
}

main() {
    print_header
    
    check_prerequisites
    show_file_structure
    show_usage_examples
    simulate_output
    test_scripts
    show_next_steps
    
    echo -e "\n${GREEN}Demo completed!${NC}"
    echo -e "Run ${CYAN}./aws_resource_tracker.sh${NC} to start tracking your AWS resources.\n"
}

# Handle script interruption
trap 'echo -e "\n${RED}Demo interrupted${NC}"; exit 1' INT TERM

# Run main function
main "$@"