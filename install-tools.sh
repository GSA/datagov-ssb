#!/bin/bash
set -ex

# TODO: Check sha256 sums
HELM_VERSION="3.7.1"
KUBECTL_VERSION="1.22.3"

AWS_IAM_AUTH_VERSION_URL="https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator"

BASE_URL="https://get.helm.sh"
TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"

# Install the Helm binary
curl -f -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm helm && \
    chmod +x helm && \
    rm -rf linux-amd64

# Install kubectl
curl -f -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x kubectl

# Install aws-iam-authenticator
curl -f -LO ${AWS_IAM_AUTH_VERSION_URL} && \
    chmod +x aws-iam-authenticator

alias aws-iam-authenticator="`pwd`/aws-iam-authenticator"
alias helm="`pwd`/helm"
alias kubectl="`pwd`/kubectl"
