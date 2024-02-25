#!/bin/bash

set -eo pipefail
rm -rf pkg

# Create venv first...

cd /home/ubuntu/acg-practice/kinesis/venv/lib/python3.10/site-packages
zip -r ../../../../pkg.zip .
cd /home/ubuntu/acg-practice/kinesis
zip pkg.zip lambda_function.py

aws lambda update-function-code --function-name put-s3-j7irn \
    --zip-file fileb:///home/ubuntu/acg-practice/kinesis/pkg.zip

    
    