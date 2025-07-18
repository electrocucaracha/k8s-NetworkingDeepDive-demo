FROM ubuntu:22.04

# hadolint ignore=DL3008
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  bpfcc-tools=0.18.0+ds-2 \
  "linux-headers-$(uname -r)" \
  iproute2=5.15.0-1ubuntu2 \
  python3=3.10.6-1~22.04.1 \
  python3-bpfcc=0.18.0+ds-2 \
  python3-pyroute2=0.6.4-3ubuntu2 && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /opt/ebpf/
COPY src/network.* /opt/ebpf/

CMD ["/usr/bin/python3", "/opt/ebpf/network.py"]
