FROM kindest/node:v1.30.2

COPY bin/plugin.sh /opt/cni/bin/bash-cni

RUN DEBIAN_FRONTEND=noninteractive clean-install \
    bridge-utils=1.7.1-1 \
    jq=1.6-2.1 \
    prips=1.2.0-1
