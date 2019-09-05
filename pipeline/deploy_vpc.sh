#!/bin/bash

AWS_REGION="$1"
STACK_NAME="$2"
ENVIRONMENT="$3"

# === BEGIN ===
aws cloudformation deploy \
	--no-fail-on-empty-changeset \
	--template-file cloudformation/vpc.yaml \
	--stack-name "$STACK_NAME"-vpc \
	--capabilities CAPABILITY_NAMED_IAM \
	--region "$AWS_REGION" \
	--tags Environment="$ENVIRONMENT" Owner=beam Project="$STACK_NAME" \
	--parameter-overrides \
	Environment="$ENVIRONMENT" \
	Service="$STACK_NAME"
