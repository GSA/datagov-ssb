#!/bin/bash
set -ex

CSB_VERSION="v0.17.10"
SMS_BROKERPAK_VERSION="v2.1.0"

# Set up an app dir and bin dir
mkdir -p app-sms/bin

# Generate a .profile to be run at startup for mapping VCAP_SERVICES to needed
# environment variables
cat > app-sms/.profile << 'EOF'
# Locate additional binaries needed by the deployed brokerpaks
export PATH="$PATH:${PWD}/bin"
EOF
chmod +x app-sms/.profile

# Add the cloud-service-broker binary
(cd app-sms && curl -f -L -o cloud-service-broker https://github.com/cloudfoundry/cloud-service-broker/releases/download/${CSB_VERSION}/cloud-service-broker.linux) && \
    chmod +x app-sms/cloud-service-broker

# Add the brokerpak(s)
(cd app-sms && curl -f -LO https://github.com/GSA/ttsnotify-brokerpak-sms/releases/download/${SMS_BROKERPAK_VERSION}/ttsnotify-brokerpak-sms-${SMS_BROKERPAK_VERSION}.brokerpak)
