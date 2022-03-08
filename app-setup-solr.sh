#!/bin/bash
set -ex

CSB_VERSION="0.4.1"
DATAGOV_BROKERPAK_SOLR_VERSION="0.20.2"

# TODO: Check sha256 sums
HELM_VERSION="3.7.1"
KUBECTL_VERSION="1.22.3"

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
(cd app-solr && curl -f -L -o cloud-service-broker https://github.com/cloudfoundry-incubator/cloud-service-broker/releases/download/${CSB_VERSION}/cloud-service-broker.linux) && \
    chmod +x app-solr/cloud-service-broker

# Add the brokerpak(s)
(cd app-solr && curl -f -LO https://github.com/GSA/datagov-brokerpak-solr/releases/download/${DATAGOV_BROKERPAK_SOLR_VERSION}/datagov-services-pak-${DATAGOV_BROKERPAK_SOLR_VERSION}.brokerpak)

# Install the Helm binary
curl -f -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm app-solr/bin/helm && \
    chmod +x app-solr/bin/helm && \
    rm -rf linux-amd64

# Install kubectl
curl -f -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    mv kubectl app-solr/bin/kubectl && \
    chmod +x app-solr/bin/kubectl
    
# Create a manifest for pushing by hand, if necessary
cat > manifest-solr.yml << MANIFEST
---
# Make a copy of vars-solr-template.yml for each deployment target, editing the
# values to match your expectations. Then push with `cf push ssb-solr -f
# manifest-solr.yml --vars-file vars-solr-ENV_NAME`
applications:
- name: ssb-solr
  path: app-solr
  buildpacks:
  - binary_buildpack
  command: source .profile && ./cloud-service-broker serve
  instances: 1
  memory: 256M
  disk_quota: 2G
  routes:
  - route: ssb-solr-((ORG))-((SPACE)).app.cloud.gov
  env: 
    SECURITY_USER_NAME: ((SECURITY_USER_NAME))
    SECURITY_USER_PASSWORD: ((SECURITY_USER_PASSWORD))
    AWS_ACCESS_KEY_ID: ((AWS_ACCESS_KEY_ID))
    AWS_SECRET_ACCESS_KEY: ((AWS_SECRET_ACCESS_KEY))
    AWS_DEFAULT_REGION: ((AWS_DEFAULT_REGION))
    DB_TLS: "skip-verify"
    GSB_COMPATIBILITY_ENABLE_CATALOG_SCHEMAS: true
    GSB_COMPATIBILITY_ENABLE_CF_SHARING: true
    AWS_ZONE: ((AWS_ZONE))
MANIFEST
cat > vars-solr-template.yml << VARS
AWS_ACCESS_KEY_ID: your-key-id
AWS_SECRET_ACCESS_KEY: your-key-secret
AWS_DEFAULT_REGION: us-west-2
AWS_ZONE: your-ssb-zone
SECURITY_USER_NAME: your-broker-username
SECURITY_USER_PASSWORD: your-broker-password
ORG: gsa-datagov
SPACE: your-space
VARS
