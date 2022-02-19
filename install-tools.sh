#!/bin/bash
set -ex

# TODO: Check sha256 sums
HELM_VERSION="3.7.1"
KUBECTL_VERSION="1.22.3"

AWS_IAM_AUTH_VERSION_URL="https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator"

BASE_URL="https://get.helm.sh"
TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"

# Set up an app dir and bin dir
mkdir -p bin

# Install the Helm binary
curl -f -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm bin/helm && \
    chmod +x bin/helm && \
    rm -rf linux-amd64

# Install kubectl
curl -f -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl bin/kubectl && \
    chmod +x bin/kubectl

# Install aws-iam-authenticator
curl -f -LO ${AWS_IAM_AUTH_VERSION_URL} && \
    mv aws-iam-authenticator bin/aws-iam-authenticator && \
    chmod +x bin/aws-iam-authenticator
    

