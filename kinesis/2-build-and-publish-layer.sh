#!/bin/bash

set -eo pipefail
rm -rf pkg

deactivate || true
rm -rf venv
rm -f pkg.zip

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

# NOTE: You will have to change this manually. It's not in terraform. 
ROLE="arn:aws:iam::258612289645:role/lambdaRole"

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