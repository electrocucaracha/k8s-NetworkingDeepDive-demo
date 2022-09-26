FROM ubuntu:20.04

# hadolint ignore=DL3008
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  bpfcc-tools=0.12.0-2 \ 
  "linux-headers-$(uname -r)" \
  iproute2=5.5.0-1ubuntu1 \
  python3=3.8.2-0ubuntu2 \
  python3-bpfcc=0.12.0-2 \
  python3-pyroute2=0.5.9-0ubuntu2 && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /opt/ebpf/
COPY src/network.* /opt/ebpf/

CMD ["/usr/bin/python3", "/opt/ebpf/network.py"]
