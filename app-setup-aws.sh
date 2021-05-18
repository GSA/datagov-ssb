#!/bin/bash
set -ex

AWS_BROKERPAK_VERSION="1.1.0-rc.6-gsa"

# Set up an app dir and bin dir
mkdir -p app-aws/bin

# Generate a .profile to be run at startup for mapping VCAP_SERVICES to needed
# environment variables
cat > app-aws/.profile << 'EOF'
# Locate additional binaries needed by the deployed brokerpaks
export PATH="$PATH:${PWD}/bin"
EOF
chmod +x app-aws/.profile

# Add the cloud-service-broker binary
(cd app-aws && curl -f -L -o cloud-service-broker https://github.com/cloudfoundry-incubator/cloud-service-broker/releases/download/0.2.2/cloud-service-broker.linux) && \
    chmod +x app-aws/cloud-service-broker

# Add the brokerpak(s)
(cd app-aws && curl -f -LO https://github.com/GSA/csb-brokerpak-aws/releases/download/${AWS_BROKERPAK_VERSION}/aws-services-${AWS_BROKERPAK_VERSION}.brokerpak)
