FROM kindest/node:v1.27.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive clean-install \
    bridge-utils=1.7-1ubuntu3 \
    tcpdump=4.99.1-3build2 \
    tshark=3.6.2-2
