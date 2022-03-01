#!/bin/bash
set -ex
APP_NAME=app-solrcloud
CSB_VERSION="0.4.1"
DATAGOV_BROKERPAK_SOLR_VERSION="v1.0.6"

# TODO: Check sha256 sums
HELM_VERSION="3.7.1"
KUBECTL_VERSION="1.22.3"

BASE_URL="https://get.helm.sh"
TAR_FILE="helm-v${HELM_VERSION}-linux-amd64.tar.gz"

# Set up an app dir and bin dir
mkdir -p $APP_NAME/bin

# Generate a .profile to be run at startup for mapping VCAP_SERVICES to needed
# environment variables
# export SERVICE_NAME=ssb-solrcloud-k8s
cat > $APP_NAME/.profile << 'EOF'
# Locate additional binaries needed by the deployed brokerpaks
export PATH="$PATH:${PWD}/bin"

# Export credentials for the k8s cluster and namespace where the Solr brokerpak
# should manage instances of SolrCloud. We get these from the binding directly.
export SOLR_SERVER=$(echo $VCAP_SERVICES | jq -r '.[][]| select(.name=="ssb-solrcloud-k8s") | .credentials.server')
export SOLR_CLUSTER_CA_CERTIFICATE=$(echo $VCAP_SERVICES | jq -r '.[][]| select(.name=="ssb-solrcloud-k8s") | .credentials.certificate_authority_data')
export SOLR_TOKEN=$(echo $VCAP_SERVICES | jq -r '.[][]| select(.name=="ssb-solrcloud-k8s") | .credentials.token')
export SOLR_NAMESPACE=$(echo $VCAP_SERVICES | jq -r '.[][]| select(.name=="ssb-solrcloud-k8s") | .credentials.namespace')
export SOLR_DOMAIN_NAME=$(echo $VCAP_SERVICES | jq -r '.[][]| select(.name=="ssb-solrcloud-k8s") | .credentials.domain_name')
EOF
chmod +x $APP_NAME/.profile

# Add the cloud-service-broker binary
(cd $APP_NAME && curl -f -L -o cloud-service-broker https://github.com/cloudfoundry-incubator/cloud-service-broker/releases/download/${CSB_VERSION}/cloud-service-broker.linux) && \
    chmod +x $APP_NAME/cloud-service-broker

# Add the brokerpak(s)
(cd $APP_NAME && curl -f -LO https://github.com/GSA/datagov-brokerpak-solr/releases/download/${DATAGOV_BROKERPAK_SOLR_VERSION}/datagov-brokerpak-solr-${DATAGOV_BROKERPAK_SOLR_VERSION}.brokerpak)

# Install the Helm binary
curl -f -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm $APP_NAME/bin/helm && \
    chmod +x $APP_NAME/bin/helm && \
    rm -rf linux-amd64

# Install kubectl
curl -f -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl $APP_NAME/bin/kubectl && \
    chmod +x $APP_NAME/bin/kubectl
    

