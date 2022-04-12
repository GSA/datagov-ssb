#!/bin/bash
set -ex

CSB_VERSION="0.10.0"
EKS_BROKERPAK_VERSION="v1.0.2"

# TODO: Check sha256 sums
HELM_VERSION="3.7.1"
KUBECTL_VERSION="1.22.3"

AWS_IAM_AUTH_VERSION_URL="https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator"

BASE_URL="https://get.helm.sh"
TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"

# Set up an app dir and bin dir
mkdir -p app-eks/bin

# Generate a .profile to be run at startup for mapping VCAP_SERVICES to needed
# environment variables
cat > app-eks/.profile << 'EOF'
# Locate additional binaries needed by the deployed brokerpaks
export PATH="$PATH:${PWD}/bin"
EOF
chmod +x app-eks/.profile

# Add the cloud-service-broker binary
(cd app-eks && curl -f -L -o cloud-service-broker https://github.com/cloudfoundry-incubator/cloud-service-broker/releases/download/${CSB_VERSION}/cloud-service-broker.linux) && \
    chmod +x app-eks/cloud-service-broker

# Add the brokerpak(s)
(cd app-eks && curl -f -LO https://github.com/GSA/datagov-brokerpak-eks/releases/download/${EKS_BROKERPAK_VERSION}/datagov-brokerpak-eks-${EKS_BROKERPAK_VERSION}.brokerpak)

# Install the Helm binary
curl -f -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm app-eks/bin/helm && \
    chmod +x app-eks/bin/helm && \
    rm -rf linux-amd64

# Install kubectl
curl -f -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl app-eks/bin/kubectl && \
    chmod +x app-eks/bin/kubectl

# Install aws-iam-authenticator
curl -f -LO ${AWS_IAM_AUTH_VERSION_URL} && \
    mv aws-iam-authenticator app-eks/bin/aws-iam-authenticator && \
    chmod +x app-eks/bin/aws-iam-authenticator
    

