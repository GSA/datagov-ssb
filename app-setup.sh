#!/bin/bash
set -ex

AWS_BROKERPAK_VERSION="0.1.0-gsa" # 1.1.0-rc5
EKS_BROKERPAK_VERSION="0.16.0"
DATAGOV_BROKERPAK_VERSION="0.10.0"

# TODO: Check sha256 sums
HELM_VERSION="3.2.1"
KUBECTL_VERSION="1.17.5"
KUSTOMIZE_VERSION="v3.8.1"

AWS_IAM_AUTH_VERSION_URL="https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/aws-iam-authenticator"

BASE_URL="https://get.helm.sh"
TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"

# Set up an app dir and bin dir
mkdir -p app/bin

# Add the bin dir the application's path at app startup
echo 'export PATH="$PATH:${PWD}/bin"' > app/.profile
chmod +x app/.profile

# Add the cloud-service-broker binary
(cd app && curl -f -L -o cloud-service-broker https://github.com/cloudfoundry-incubator/cloud-service-broker/releases/download/0.2.2/cloud-service-broker.linux) && \
    chmod +x app/cloud-service-broker

# Add the brokerpak(s)
(cd app && curl -f -LO https://github.com/GSA/eks-brokerpak/releases/download/v${EKS_BROKERPAK_VERSION}/eks-services-pack-${EKS_BROKERPAK_VERSION}.brokerpak)
# Note the datagov-brokerpak filename isn't parameterized... It doesn't match
# the release name upstream yet.
(cd app && curl -f -LO https://github.com/GSA/datagov-brokerpak/releases/download/v${DATAGOV_BROKERPAK_VERSION}/datagov-services-pak-1.0.0.brokerpak)

# Temporarily use Aaron's fork
# (cd app && curl -f -LO https://github.com/adborden/csb-brokerpak-aws/releases/download/v${AWS_BROKERPAK_VERSION}/aws-services-${AWS_BROKERPAK_VERSION}.brokerpak)
(cd app && curl -f -LO https://github.com/adborden/csb-brokerpak-aws/releases/download/v0.1.0-gsa/aws-services-0.1.0.brokerpak)

# Install the Helm binary
curl -f -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm app/bin/helm && \
    chmod +x app/bin/helm && \
    rm -rf linux-amd64

# Install kubectl
curl -f -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl app/bin/kubectl && \
    chmod +x app/bin/kubectl

# Install aws-iam-authenticator
curl -f -LO ${AWS_IAM_AUTH_VERSION_URL} && \
    mv aws-iam-authenticator app/bin/aws-iam-authenticator && \
    chmod +x app/bin/aws-iam-authenticator
    

