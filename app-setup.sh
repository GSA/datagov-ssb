#!/bin/bash

# TODO: Check sha256 sums

HELM_VERSION="3.2.1"
KUBECTL_VERSION="1.17.5"
KUSTOMIZE_VERSION="v3.8.1"

AWS_IAM_AUTH_VERSION_URL="https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/aws-iam-authenticator"

BASE_URL="https://get.helm.sh"
TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"

set -ex

# Set up an app dir and bin dir
mkdir -p app/bin

# Add the bin dir the application's path at app startup
echo 'export PATH="$PATH:${PWD}/bin"' > app/.profile
chmod +x app/.profile

# Add the cloud-service-broker binary
(cd app && curl -L -o cloud-service-broker https://github.com/cloudfoundry-incubator/cloud-service-broker/releases/download/0.2.2/cloud-service-broker.linux) && \
    chmod +x app/cloud-service-broker

# Add the brokerpak(s)
(cd app && curl -LO https://github.com/GSA/eks-brokerpak/releases/download/v0.5.0/eks-services-pack-1.0.0.brokerpak)
(cd app && curl -LO https://github.com/GSA/datagov-brokerpak/releases/download/v0.6.0/datagov-services-pak-1.0.0.brokerpak)
(cd app && curl -LO https://github.com/cloudfoundry-incubator/csb-brokerpak-aws/releases/download/1.1.0-rc.5/aws-services-1.1.0-rc.5.brokerpak)

# Install the Helm binary
curl -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm app/bin/helm && \
    chmod +x app/bin/helm && \
    rm -rf linux-amd64

# Install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl app/bin/kubectl && \
    chmod +x app/bin/kubectl

# Install aws-iam-authenticator
curl -LO ${AWS_IAM_AUTH_VERSION_URL} && \
    mv aws-iam-authenticator app/bin/aws-iam-authenticator && \
    chmod +x app/bin/aws-iam-authenticator
    

