#!/bin/bash

set -eo pipefail
rm -rf pkg

rm -rf venv
rm -f pkg.zip

# Get the current Python version
python_version=$(python --version 2>&1 | awk '{print $2}')
required_version="3.10"

# Check if the current Python version starts with the required version
if [[ $python_version != $required_version.* ]]; then
  echo "Python version is not 3.10. Current version is $python_version. Run this script with Python 3.10"
  exit 1  # Exit with a failure status
else
  echo "Python version is 3.10"
fi

# Create venv first...
python3 -m venv venv
./venv/bin/pip install -U pip setuptools

# urllib3>2 breaks lambda
./venv/bin/pip install -U requests 'urllib3<2'


cd ./venv/lib/python3.10/site-packages
zip -r ../../../../pkg.zip .
cd ../../../..
zip pkg.zip lambda_function.py

FUNCTION_NAME="put-s3-j7irn"
ZIP_FILE="fileb://./pkg.zip"
HANDLER="lambda_function.lambda_handler" 

# Obtain the current AWS account ID
current_aws_id=$(aws sts get-caller-identity --query "Account" --output text)

# Check if the AWS CLI command was successful
if [ $? -ne 0 ]; then
    echo "Failed to retrieve AWS account ID. Make sure you are logged in to AWS CLI."
    exit 1
fi

# Define the new role with the current AWS ID
ROLE="arn:aws:iam::$current_aws_id:role/lambdaRole"
echo "Updated ROLE: $ROLE"

# Check if the Lambda function exists
if aws lambda get-function --function-name $FUNCTION_NAME 2>/dev/null; then
    echo "Function exists, updating code..."
    aws lambda update-function-code --function-name $FUNCTION_NAME --zip-file $ZIP_FILE
else
    echo "Function does not exist, creating..."
    aws lambda create-function --function-name $FUNCTION_NAME \
        --zip-file $ZIP_FILE \
        --runtime python3.10 \
        --handler $HANDLER \
        --timeout 60 \
        --role $ROLE
fi