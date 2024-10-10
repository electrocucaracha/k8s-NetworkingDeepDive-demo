# eBPF

eBPF stands for extended Berkeley Packet Filter. eBPF is an interface added into
the Linux kernel in 2014 that lets users inject code to observe or modify kernel
behavior. The added code can run immediately: you don’t need to recompile or
restart Linux. You also don’t need to share your code with anyone else.

What eBPF provides to the Linux kernel is the extensibility to enable developers
to program the Linux kernel to quickly build intelligent or feature-rich
functions based on their business needs.

## Demo output example

The following output was capture from the _deploy.log_ file generated
from the `vagrant up` execution.

<!-- markdownlint-disable MD010 -->

```bash

23:28:14 - INFO: Ping original service
64 bytes from 10.0.2.173: icmp_seq=1 ttl=64 time=0.161 ms
64 bytes from 10.0.2.173: icmp_seq=2 ttl=64 time=0.344 ms
64 bytes from 10.0.2.173: icmp_seq=3 ttl=64 time=1.19 ms
fca1d88d7bcb65e0a1abc66ca05b766ed3d494e575308c4dfe338810556dbe13

23:28:18 - INFO: Ping bypass service
64 bytes from 172.80.0.2: icmp_seq=1 ttl=64 time=0.245 ms
64 bytes from 172.80.0.2: icmp_seq=2 ttl=64 time=0.101 ms
64 bytes from 172.80.0.2: icmp_seq=3 ttl=64 time=0.518 ms

23:28:20 - INFO: Bypass logs
Ready
b'            ping-7396    [001] ..s1   125.386934: 0: [tc_pingpong] ingress got packet'
b'            ping-7396    [001] ..s1   125.387031: 0: [tc_pingpong] ICMP request for 20050ac type 8'

23:28:20 - INFO: Trace events difference
	net:net_dev_queue:dev=docker0
	net:net_dev_queue:dev=eth0
net:net_dev_queue:dev=lo
	net:net_dev_queue:dev=veth682c825
	net:net_dev_start_xmit:dev=docker0 queue_mapping=0
	net:net_dev_start_xmit:dev=eth0 queue_mapping=0
net:net_dev_start_xmit:dev=lo queue_mapping=0
	net:net_dev_start_xmit:dev=veth682c825 queue_mapping=0
	net:net_dev_xmit:dev=docker0
	net:net_dev_xmit:dev=eth0
net:net_dev_xmit:dev=lo
	net:net_dev_xmit:dev=veth682c825
	net:netif_receive_skb:dev=docker0
	net:netif_receive_skb:dev=eth0
net:netif_receive_skb:dev=lo
	net:netif_receive_skb:dev=veth682c825
	net:netif_receive_skb_entry:dev=docker0
	net:netif_receive_skb_exit:ret=0
	net:netif_rx:dev=eth0
net:netif_rx:dev=lo
	net:netif_rx:dev=veth682c825
	net:netif_rx_entry:dev=eth0
net:netif_rx_entry:dev=lo
	net:netif_rx_entry:dev=veth682c825

23:28:20 - INFO: Show bypass ingress traffic controls
filter parent ffff: protocol all pref 49152 bpf chain 0
filter parent ffff: protocol all pref 49152 bpf chain 0 handle 0x1 flowid :1 tc_pingpong not_in_hw id 113 tag 4b23c39d9c6d4df8 jited
	action order 1: gact action drop
	 random type none pass val 0
	 index 1 ref 1 bind 1

bypass
```
