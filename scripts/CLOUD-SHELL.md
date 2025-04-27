# CloudShell Commands

- Create an access key for `cloud_user`
`aws iam create-access-key --user-name cloud_user`

- Launch an instance

```shell
#!/bin/bash

set -e
set -o pipefail

# === CONFIGURATION ===
AMI_ID="ami-071226ecf16aa7d96" # Amazon Linux 2023
KEY_NAME="lab1"
KEY_FILE="${KEY_NAME}.pem"
SECURITY_GROUP_NAME="launch-wizard-1"
SECURITY_GROUP_DESC="launch-wizard-1 created $(date -Iseconds)"
TAG_NAME="MyInstance"
IAM_USER_NAME="cloud_user"

echo "🔍 Fetching default VPC ID..."
VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=isDefault,Values=true \
    --query 'Vpcs[0].VpcId' \
    --output text)

echo "✅ Found default VPC."

# === CREATE KEY PAIR ===
if [[ ! -f "$KEY_FILE" ]]; then
    echo "🔐 Creating EC2 key pair..."
    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --key-type rsa \
        --key-format pem \
        --query 'KeyMaterial' \
        --output text > "$KEY_FILE"
    chmod 400 "$KEY_FILE"
    echo "✅ Key pair created and saved."
else
    echo "ℹ️ Key pair already exists. Skipping creation."
fi

# === CREATE SECURITY GROUP ===
echo "🛡️ Creating security group..."
SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name "$SECURITY_GROUP_NAME" \
    --description "$SECURITY_GROUP_DESC" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)

echo "✅ Security group created."

# === AUTHORIZE SSH ACCESS ===
echo "🔓 Authorizing SSH access on port 22..."
aws ec2 authorize-security-group-ingress \
    --group-id "$SECURITY_GROUP_ID" \
    --ip-permissions '[
        {
            "IpProtocol": "tcp",
            "FromPort": 22,
            "ToPort": 22,
            "IpRanges": [{"CidrIp": "0.0.0.0/0"}]
        }
    ]'

echo "✅ Port 22 access granted."

# === GET SUBNET ===
echo "📡 Fetching subnet from default VPC..."
SUBNET_ID=$(aws ec2 describe-subnets \
    --filters Name=vpc-id,Values="$VPC_ID" \
    --query "Subnets[0].SubnetId" \
    --output text)

echo "✅ Subnet found."

# === LAUNCH INSTANCE ===
echo "🚀 Launching EC2 instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --subnet-id "$SUBNET_ID" \
    --associate-public-ip-address \
    --block-device-mappings "DeviceName=/dev/xvda,Ebs={VolumeSize=30}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "✅ Instance launched."

# === CREATE IAM USER AND CREDENTIALS ===
echo "🔑 Creating IAM user and access keys..."

aws iam create-user --user-name "$IAM_USER_NAME" > /dev/null 2>&1 || echo "ℹ️ IAM user already exists. Skipping user creation."

CREDS=$(aws iam create-access-key --user-name "$IAM_USER_NAME" \
    --query '{AccessKeyId:AccessKey.AccessKeyId,SecretAccessKey:AccessKey.SecretAccessKey}' \
    --output json)

ACCESS_KEY_ID=$(echo "$CREDS" | jq -r .AccessKeyId)
SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r .SecretAccessKey)

# === OUTPUT SECTION ===

echo ""
echo "🎉 === DONE! Copy-paste the following values: ==="

echo ""
echo "🔐 Your EC2 Key (PEM file):"
echo "----------------------------------------"
cat "$KEY_FILE"
echo "----------------------------------------"

echo ""
echo "🆔 Your EC2 Instance ID:"
echo "$INSTANCE_ID"

echo ""
echo "🔑 AWS Credentials for IAM user '$IAM_USER_NAME':"
echo "AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY"

echo ""
echo "⚠️ Save these credentials securely. They will not be shown again!"
```
