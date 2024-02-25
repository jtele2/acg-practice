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

aws lambda update-function-code --function-name put-s3-j7irn \
    --zip-file fileb:///home/ubuntu/acg-practice/kinesis/pkg.zip

    
    