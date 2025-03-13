FROM kindest/node:v1.32.3

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive clean-install \
    bridge-utils=1.7.1-1 \
    tcpdump=4.99.3-1 \
    tshark=4.0.17-0+deb12u1
