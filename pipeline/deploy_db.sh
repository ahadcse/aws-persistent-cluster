#!/bin/bash

AWS_REGION="$1"
STACK_NAME="$2"
ENVIRONMENT="$3"

DB_NAME="$4"
DB_CLUSTER_NAME="$5"

# === ():
# Get encrypted parameter (SSM), if none is set generate a random string, encrypt it and echo it
function get_encrypted_password() {
    local encrypted=$(aws ssm get-parameter --name "/config/$1/mysql/master-password" --query Parameter.Value --output text)
    if [ -z $encrypted ]; then
        local password=$(pwgen -1 32 1)
        encrypted=$(aws kms encrypt --key-id alias/dbPasswordCryptoKey --plaintext $password --query CiphertextBlob --output text)
    fi
    echo "$encrypted"
    return 0
}

# === (value):
# Decrypt base64 encoded Ciphertextblob and echo it
function decrypt_value() {
    local decrypted=$(aws kms decrypt --ciphertext-blob fileb://<(echo $1 | base64 -d) --output text --query Plaintext | base64 -d)
    echo "$decrypted"
}

# === BEGIN ===
decrypted=$(get_encrypted_password $STACK_NAME)
echo $decrypted


aws cloudformation deploy \
    --no-fail-on-empty-changeset \
    --template-file cloudformation/mysql.yaml \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$AWS_REGION" \
    --tags Environment="$ENVIRONMENT" Project="$STACK_NAME" \
    --parameter-overrides \
    Environment="$ENVIRONMENT" \
    Service="$STACK_NAME" \
    DatabaseName="$DB_NAME" \
    DBClusterName="$DB_CLUSTER_NAME" \
    DBMasterPasswordEncrypted="$decrypted" \
    DBMasterPasswordRaw="$(decrypt_value $decrypted)"
