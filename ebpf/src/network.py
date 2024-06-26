"""
Loads a ebpf network function
"""

from bcc import BPF  # pylint: disable=import-error
from pyroute2 import IPRoute  # pylint: disable=import-error

INTERFACE = "eth0"

ipr = IPRoute()
links = ipr.link_lookup(ifname=INTERFACE)
idx = links[0]

ipr.tc("add", "ingress", idx, "ffff:")

b = BPF(src_file="network.c")
fi = b.load_func("tc_pingpong", BPF.SCHED_CLS)
ipr.tc(
    "add-filter",
    "bpf",
    idx,
    ":1",
    fd=fi.fd,
    name=fi.name,
    parent="ffff:",
    action="drop",
    classid=1,
)

print("Ready")

try:
    b.trace_print()
except KeyboardInterrupt:
    print("\n unloading")
    ipr.tc("del", "ingress", idx, "ffff:")
