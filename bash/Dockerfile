FROM kindest/node:v1.25.0

COPY bin/plugin.sh /opt/cni/bin/bash-cni

RUN DEBIAN_FRONTEND=noninteractive clean-install \
    bridge-utils=1.7-1ubuntu2 \
    jq=1.6-2.1ubuntu2 \
    prips=1.1.1-3
