FROM kindest/node:v1.35.1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive clean-install \
    bridge-utils=1.7.1-4+b1 \
    tcpdump=4.99.5-2 \
    tshark=4.4.14-0+deb13u1
