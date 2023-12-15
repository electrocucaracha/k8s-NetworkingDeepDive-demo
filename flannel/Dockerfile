FROM kindest/node:v1.29.0

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive clean-install \
    bridge-utils=1.7-1 \
    tcpdump=4.99.0-2+deb11u1 \
    tshark=3.4.10-0+deb11u1
