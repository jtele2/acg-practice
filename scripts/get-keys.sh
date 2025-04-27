#!/bin/bash

# Run this the AWS CloudShell to create access keys for the `cloud_user` IAM user.

set --errexit  # Exit immediately if a command exits with a non-zero status
set --nounset  # Treat unset variables as an error and exit immediately
set --pipefail # Return the exit status of the last command in the pipeline that failed
# set --xtrace   # Print each command before executing it

# === CREATE IAM USER AND CREDENTIALS ===
IAM_USER_NAME="cloud_user"

# Delete all existing access keys for the IAM user
echo "🗑️ Deleting existing access keys for IAM user '$IAM_USER_NAME'..."
EXISTING_KEYS=$(aws iam list-access-keys --user-name "$IAM_USER_NAME" --query 'AccessKeyMetadata[].AccessKeyId' --output text)

if [[ -n "$EXISTING_KEYS" ]]; then
    for KEY_ID in $EXISTING_KEYS; do
        read -p "❓ Are you sure you want to delete access key '$KEY_ID'? (y/n): " CONFIRM
        if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
            aws iam delete-access-key --user-name "$IAM_USER_NAME" --access-key-id "$KEY_ID"
            echo "✅ Deleted access key: $KEY_ID"
        else
            echo "⏭️ Skipped deletion of access key: $KEY_ID"
        fi
    done
else
    echo "🔒 No existing access keys found for user '$IAM_USER_NAME'."
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
echo "🔑 AWS Credentials for IAM user '$IAM_USER_NAME':"
echo "$ACCESS_KEY_ID"
echo "$SECRET_ACCESS_KEY"

echo ""
