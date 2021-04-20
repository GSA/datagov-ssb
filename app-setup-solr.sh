#!/bin/bash
set -ex

DATAGOV_BROKERPAK_VERSION="0.19.2"

# TODO: Check sha256 sums
HELM_VERSION="3.2.1"
KUBECTL_VERSION="1.20.5"
KUSTOMIZE_VERSION="v3.8.1"

BASE_URL="https://get.helm.sh"
TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"

# Set up an app dir and bin dir
mkdir -p app-solr/bin

# Generate a .profile to be run at startup for mapping VCAP_SERVICES to needed
# environment variables
cat > app-solr/.profile << 'EOF'
# Locate additional binaries needed by the deployed brokerpaks
export PATH="$PATH:${PWD}/bin"

# Export credentials for the k8s cluster and namespace where the Solr brokerpak
# should manage instances of SolrCloud. We get these from the binding directly.
export SOLR_SERVER=$(echo $VCAP_SERVICES | jq -r '.["aws-eks-service"][] | .credentials.server')
export SOLR_CLUSTER_CA_CERTIFICATE=$(echo $VCAP_SERVICES | jq -r '.["aws-eks-service"][] | .credentials.certificate_authority_data')
export SOLR_TOKEN=$(echo $VCAP_SERVICES | jq -r '.["aws-eks-service"][] | .credentials.token')
export SOLR_NAMESPACE=$(echo $VCAP_SERVICES | jq -r '.["aws-eks-service"][] | .credentials.namespace')
export SOLR_DOMAIN_NAME=$(echo $VCAP_SERVICES | jq -r '.["aws-eks-service"][] | .credentials.domain_name')
EOF
chmod +x app-solr/.profile

# Add the cloud-service-broker binary
(cd app-solr && curl -f -L -o cloud-service-broker https://github.com/cloudfoundry-incubator/cloud-service-broker/releases/download/0.2.2/cloud-service-broker.linux) && \
    chmod +x app-solr/cloud-service-broker

# Add the brokerpak(s)
(cd app-solr && curl -f -LO https://github.com/GSA/datagov-brokerpak/releases/download/${DATAGOV_BROKERPAK_VERSION}/datagov-services-pak-${DATAGOV_BROKERPAK_VERSION}.brokerpak)

# Install the Helm binary
curl -f -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm app-solr/bin/helm && \
    chmod +x app-solr/bin/helm && \
    rm -rf linux-amd64

# Install kubectl
curl -f -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl app-solr/bin/kubectl && \
    chmod +x app-solr/bin/kubectl
    

