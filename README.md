# AWS Resource Tracker

A comprehensive shell scripting project that automates AWS resource usage tracking for S3, EC2, Lambda, and IAM Users. The system generates detailed daily reports using cron jobs, running automatically every day at 6:30 PM and storing output in timestamped log files for monitoring and auditing purposes.

## Features

- **Automated Resource Tracking**: Monitors AWS resources across multiple services
- **S3 Bucket Monitoring**: Lists all buckets with creation dates and calculates sizes
- **EC2 Instance Tracking**: Tracks instances with detailed information including state, type, and launch time
- **Lambda Function Monitoring**: Lists all functions with runtime, size, and modification details
- **IAM User Management**: Tracks users with creation dates and console access status
- **Automated Scheduling**: Daily execution at 6:30 PM via cron jobs
- **Timestamped Logging**: All reports stored with timestamps for historical tracking
- **Comprehensive Error Handling**: Robust error handling and logging
- **Log Management**: Automatic log cleanup to prevent disk space issues
- **Easy Setup**: Simple installation and configuration scripts

## Prerequisites

### System Requirements
- Linux/Unix system with bash shell
- `cron` service installed and running
- Internet connectivity for AWS API calls

### AWS Requirements
- AWS CLI installed and configured
- Valid AWS credentials with appropriate permissions
- IAM permissions for the following services:
  - S3: `s3:ListAllMyBuckets`, `s3:ListBucket`
  - EC2: `ec2:DescribeInstances`  
  - Lambda: `lambda:ListFunctions`
  - IAM: `iam:ListUsers`, `iam:GetLoginProfile`

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/Dushyantsharmma/aws_resource_traker.git
cd aws_resource_traker
```

### 2. Configure AWS CLI
If not already configured, set up your AWS credentials:
```bash
aws configure
```

### 3. Set Up Cron Job
Run the setup script to install the daily cron job:
```bash
./setup_cron.sh
```

### 4. Verify Installation
Check that the cron job was installed correctly:
```bash
crontab -l
```

## Usage

### Manual Execution
To run the resource tracker manually:
```bash
./aws_resource_tracker.sh
```

### Automated Execution
The script runs automatically daily at 6:30 PM via cron job. No manual intervention required.

### View Reports
Log files are stored in the `logs/` directory with timestamps:
```bash
ls -la logs/
cat logs/aws_resource_report_YYYY-MM-DD_HH-MM-SS.log
```

### Log Management
Clean up old log files:
```bash
# Keep logs from last 30 days (default)
./cleanup_logs.sh

# Keep logs from last 7 days
./cleanup_logs.sh --days 7

# Keep only newest 20 log files
./cleanup_logs.sh --max-files 20

# Dry run to see what would be deleted
./cleanup_logs.sh --dry-run
```

## Configuration

Edit `config.conf` to customize behavior:

```bash
# AWS Configuration
DEFAULT_REGION=us-east-1

# Logging Configuration
LOG_RETENTION_DAYS=30
MAX_LOG_FILES=50

# Report Settings
INCLUDE_DETAILED_S3_SIZES=true
INCLUDE_LAMBDA_CODE_SIZES=true
INCLUDE_EC2_DETAILED_INFO=true
INCLUDE_IAM_LAST_ACCESS=true

# Cron Schedule (default: 18:30 daily)
CRON_SCHEDULE="30 18 * * *"
```

## Output Format

The script generates comprehensive reports including:

### S3 Resources
- Total bucket count
- Bucket names and creation dates
- Individual bucket sizes
- Storage usage summary

### EC2 Resources  
- Total instance count
- Instance details (ID, type, state, launch time, name tags)
- Count by instance state (running, stopped, terminated)

### Lambda Resources
- Total function count
- Function details (name, runtime, last modified, code size, timeout)
- Total code size across all functions

### IAM Resources
- Total user count
- User details (username, creation date, last password use)
- Count of users with console access

### Summary Report
- Resource counts across all services
- Report generation timestamp
- Log file location

## File Structure

```
aws_resource_traker/
├── README.md                    # This documentation
├── aws_resource_tracker.sh      # Main tracking script
├── setup_cron.sh               # Cron job setup script
├── cleanup_logs.sh             # Log cleanup utility
├── config.conf                 # Configuration file
└── logs/                       # Log files directory
    ├── aws_resource_report_*.log   # Timestamped reports
    └── cron.log                    # Cron execution logs
```

## Troubleshooting

### Common Issues

1. **AWS CLI not configured**
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, and default region
   ```

2. **Permission denied errors**
   ```bash
   chmod +x *.sh
   ```

3. **AWS permission errors**
   - Ensure your AWS user/role has the required IAM permissions
   - Check AWS CLI configuration: `aws sts get-caller-identity`

4. **Cron job not running**
   ```bash
   # Check cron service status
   sudo systemctl status cron
   
   # View cron logs
   sudo journalctl -u cron
   
   # Check installed cron jobs
   crontab -l
   ```

5. **No output in log files**
   - Check cron logs: `cat logs/cron.log`
   - Verify script permissions and AWS credentials
   - Run script manually to test: `./aws_resource_tracker.sh`

### Debug Mode
Run the script with verbose output:
```bash
bash -x ./aws_resource_tracker.sh
```

## Security Considerations

- Store AWS credentials securely using AWS CLI configuration or IAM roles
- Regularly rotate AWS access keys
- Use least-privilege IAM policies
- Protect log files containing resource information
- Consider encrypting sensitive data in logs

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source. Please check the repository for license details.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review existing GitHub issues
3. Create a new issue with detailed information about your problem

## Changelog

### Version 1.0
- Initial release
- Support for S3, EC2, Lambda, and IAM resource tracking
- Automated cron job scheduling
- Comprehensive logging and error handling
- Log cleanup utilities
- Configuration file support
