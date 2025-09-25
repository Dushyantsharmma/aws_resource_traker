# AWS Resource Tracker Shell Script with Cronjob

This project automates the process of fetching AWS resource usage details (**S3, EC2, Lambda, IAM Users**) using a Bash shell script. It's scheduled with a cron job to run automatically every day at **6:30 PM**. The script generates daily, timestamped log files for easy tracking and auditing of your AWS infrastructure.

---

## Features

- Lists **S3 buckets**
- Lists **EC2 instances** (Instance IDs)
- Lists **Lambda functions**
- Lists **IAM users**
- Stores the output in timestamped log files:
  - `resource_tracker_YYYYMMDD.log`
- Automated execution via **cronjob at 6:30 PM daily**
- Captures cron execution errors in a separate file:
  - `aws_cron.log`

---

## Prerequisites

- An Ubuntu EC2 instance (or other Linux system) with Bash shell
- AWS CLI configured with necessary IAM permissions (`aws configure`)
- `jq` package installed for JSON parsing

```bash
sudo apt update
sudo apt install jq -y
```

---

## 📜 Shell Script

```bash
#!/bin/bash

#################################################
# Author: Dushyant Shrma
# Date: 25th Sep'25
# Version: V1
#
# This script will report the following AWS resource usage
# - AWS S3
# - AWS EC2
# - AWS Lambda
# - AWS IAM Users
#################################################

set -x
{
    echo "Printing list of S3 buckets"
    aws s3 ls

    echo "Printing list of EC2 instances"
    aws ec2 describe-instances | jq '.Reservations[].Instances[].InstanceId'

    echo "Printing list of Lambda functions"
    aws lambda list-functions

    echo "Printing list of IAM users"
    aws iam list-users
} > "/home/data/shell-scripting/resource_tracker_$(date +%Y%m%d).log"
```

### Make it executable:
```bash
chmod +x /home/data/shell-scripting/aws_resource_tracker.sh
```

---

## ⏰ Cronjob Setup
Open crontab:
```bash
crontab -e
```

Add the job (runs every day at 6:30 PM):
```bash
30 18 * * * /home/ubuntu/aws_resource_traker.sh >> /home/ubuntu/resource_tracker.log 2>&1
```

Save & exit.
- If using nano, press Ctrl+X.
- Press Y to confirm you want to save.
- Press Enter to confirm the file name.



---

## 📂 Output
- Example daily log file:  
  - `resource_tracker_20250915.log`  

- Cron execution logs:  
  - `resource_tracker.log`
