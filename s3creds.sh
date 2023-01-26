#!/bin/bash

# If you want to use a cloud.gov-brokered S3 broker for your Terraform state,
# this script makes it easy both to create a service key and to extract the
# bucket parameters needed for the Terraform backend configuration.
#
# If your S3 service instance has a different name, or you want a different key
# name, edit the following two lines.
#
# NOTE: This script has been tested with CF CLI v8!

SERVICE_INSTANCE_NAME="${SERVICE_INSTANCE_NAME:-notify-terraform-state}"
KEY_NAME="${KEY_NAME:-${SERVICE_INSTANCE_NAME}-ssb-key}"

cf service-key "${SERVICE_INSTANCE_NAME}" "${KEY_NAME}" &> /dev/null || cf create-service-key "${SERVICE_INSTANCE_NAME}" "${KEY_NAME}"
S3_CREDENTIALS=`cf service-key "${SERVICE_INSTANCE_NAME}" "${KEY_NAME}" | tail -n +2`

echo 'Run the following lines at your shell prompt to put the S3 bucket credentials in your environment.'
echo export AWS_ACCESS_KEY_ID=`echo "${S3_CREDENTIALS}" | jq -r .credentials.access_key_id`
echo export AWS_SECRET_ACCESS_KEY=`echo "${S3_CREDENTIALS}" | jq -r .credentials.secret_access_key`
echo export BUCKET_NAME=`echo "${S3_CREDENTIALS}" | jq -r .credentials.bucket`
echo export AWS_DEFAULT_REGION=`echo "${S3_CREDENTIALS}" | jq -r '.credentials.region'`
