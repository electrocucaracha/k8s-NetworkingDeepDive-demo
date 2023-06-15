FROM kindest/node:v1.27.3

COPY bin/plugin.sh /opt/cni/bin/bash-cni

RUN DEBIAN_FRONTEND=noninteractive clean-install \
    bridge-utils=1.7-1ubuntu3 \
    jq=1.6-2.1ubuntu3 \
    prips=1.2.0-1build1
