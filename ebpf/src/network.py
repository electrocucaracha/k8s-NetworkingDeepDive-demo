from bcc import BPF  # pylint: disable=import-error
from pyroute2 import IPRoute  # pylint: disable=import-error

interface = "eth0"

ipr = IPRoute()
links = ipr.link_lookup(ifname=interface)
idx = links[0]

try:
    ipr.tc("add", "ingress", idx, "ffff:")
except BaseException:
    print("qdisc ingress already exists")

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
