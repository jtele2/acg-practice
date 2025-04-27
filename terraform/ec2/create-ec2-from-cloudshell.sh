#!/bin/bash

# === CONFIGURATION ===
AMI_ID="ami-071226ecf16aa7d96" # Amazon Linux 2023
KEY_NAME="lab-$(date +%Y%m%d%H%M%S)"
KEY_FILE="${KEY_NAME}.pem"
SECURITY_GROUP_NAME="launch-wizard-1"
SECURITY_GROUP_DESC="launch-wizard-1 created $(date -Iseconds)"
TAG_NAME="MyInstance"
IAM_USER_NAME="cloud_user"

echo "🔍 Fetching default VPC ID..."
VPC_ID=$(aws ec2 describe-vpcs \
    --query 'Vpcs[0].VpcId' \
    --output text)

echo "✅ Found default VPC."

# === CREATE OR RECREATE KEY PAIR ===
echo "🔍 Checking if key pair '$KEY_NAME' exists..."
EXISTING_KEY=$(aws ec2 describe-key-pairs \
    --key-names "$KEY_NAME" \
    --query 'KeyPairs[0].KeyName' \
    --output text 2>/dev/null)

if [[ "$EXISTING_KEY" == "$KEY_NAME" ]]; then
    echo "🗑️ Key pair '$KEY_NAME' already exists. Deleting it..."
    aws ec2 delete-key-pair --key-name "$KEY_NAME"
    echo "✅ Key pair '$KEY_NAME' deleted."
fi

echo "🔐 Creating EC2 key pair..."
aws ec2 create-key-pair \
    --key-name "$KEY_NAME" \
    --key-type rsa \
    --key-format pem \
    --query 'KeyMaterial' \
    --output text > "$KEY_FILE"
chmod 400 "$KEY_FILE"
echo "✅ Key pair created and saved."

# === CREATE SECURITY GROUP ===
echo "🔍 Checking if security group '$SECURITY_GROUP_NAME' already exists..."
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
    --filters Name=group-name,Values="$SECURITY_GROUP_NAME" \
    --query 'SecurityGroups[0].GroupId' \
    --output text 2>/dev/null)

if [[ "$SECURITY_GROUP_ID" == "None" ]]; then
    echo "🔐 Security group not found. Creating a new one..."
    SECURITY_GROUP_ID=$(aws ec2 create-security-group \
        --group-name "$SECURITY_GROUP_NAME" \
        --description "$SECURITY_GROUP_DESC" \
        --vpc-id "$VPC_ID" \
        --query 'GroupId' \
        --output text)
    echo "✅ Security group created with ID: $SECURITY_GROUP_ID"
else
    echo "ℹ️ Security group already exists with ID: $SECURITY_GROUP_ID. Skipping creation."
fi


# === AUTHORIZE SSH ACCESS ===
echo "🔍 Checking if SSH access on port 22 is already authorized..."
EXISTING_RULE=$(aws ec2 describe-security-groups \
    --group-ids "$SECURITY_GROUP_ID" \
    --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\` && ToPort==\`22\` && IpProtocol==\`tcp\` && IpRanges[?CidrIp==\`0.0.0.0/0\`]]" \
    --output text)

if [[ -z "$EXISTING_RULE" ]]; then
    echo "🔓 Authorizing SSH access on port 22..."
    aws ec2 authorize-security-group-ingress \
        --no-cli-pager \
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
else
    echo "ℹ️ SSH access on port 22 is already authorized. Skipping."
fi

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

echo "⏳ Waiting for instance $INSTANCE_ID to be in 'running' state..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
echo "✅ Instance is running."

# Now fetch the public IP
INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "🌐 Public IP: $INSTANCE_PUBLIC_IP"

# === CREATE IAM USER AND CREDENTIALS ===
echo "🔑 Creating IAM user and access keys..."

aws iam create-user --user-name "$IAM_USER_NAME" > /dev/null 2>&1 || echo "ℹ️ IAM user already exists. Skipping user creation."
# Delete all existing access keys for the IAM user
echo "🗑️ Deleting existing access keys for IAM user '$IAM_USER_NAME'..."
EXISTING_KEYS=$(aws iam list-access-keys --user-name "$IAM_USER_NAME" --query 'AccessKeyMetadata[].AccessKeyId' --output text)

if [[ -n "$EXISTING_KEYS" ]]; then
    for KEY_ID in $EXISTING_KEYS; do
        aws iam delete-access-key --user-name "$IAM_USER_NAME" --access-key-id "$KEY_ID"
        echo "✅ Deleted access key: $KEY_ID"
    done
else
    echo "ℹ️ No existing access keys found for user '$IAM_USER_NAME'."
fi

# Create a new access key
echo "🔑 Creating a new access key for IAM user '$IAM_USER_NAME'..."
CREDS=$(aws iam create-access-key --user-name "$IAM_USER_NAME" \
    --query '{AccessKeyId:AccessKey.AccessKeyId,SecretAccessKey:AccessKey.SecretAccessKey}' \
    --output json)

ACCESS_KEY_ID=$(echo "$CREDS" | jq -r .AccessKeyId)
SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r .SecretAccessKey)
echo "✅ New access key created."

# Save the credentials to a file
CREDENTIALS_FILE="credentials"
echo "🔐 Saving credentials to file '$CREDENTIALS_FILE'..."
cat <<EOF > "$CREDENTIALS_FILE"
AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY
EOF
chmod 600 "$CREDENTIALS_FILE"
echo "✅ Credentials saved to '$CREDENTIALS_FILE'."

# === OUTPUT SECTION ===

echo ""
echo "🎉 === DONE! Copy-paste the following values: ==="

echo ""
echo "🔐 Your EC2 Key (PEM file):"
echo "----------------------------------------"
cat "$KEY_FILE"
echo "----------------------------------------"

echo ""
echo "🆔 Your EC2 Public IP:"
echo "$INSTANCE_PUBLIC_IP"

echo ""
echo "🔑 AWS Credentials for IAM user '$IAM_USER_NAME':"
echo "$ACCESS_KEY_ID"
echo "$SECRET_ACCESS_KEY"

echo ""
