#!/bin/bash

#########################
# Author: Dushyant
# Date: 11th-jan
#
# Version: v1
#
# This script will report the AWS resource usage
#########################

set -x

# AWS S3
# AWS EC2
# AWS Lamda
# AWS IAM Users


# List s3 buckets
echo "Print the list of s3 buckets "
aws s3 ls

# List EC2 Instances
echo "Print the list of ec2 instance "
aws ec2 describe-instances

# List AWS Lambda
echo "Print the list of lambda fuctions "
aws lamda list-functions


# List IAM users
echo "Print the list of IAM users "
aws iam list-users


