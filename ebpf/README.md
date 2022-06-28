# eBPF

eBPF stands for extended Berkeley Packet Filter. eBPF is an interface added into
the Linux kernel in 2014 that lets users inject code to observe or modify kernel
behavior. The added code can run immediately: you don’t need to recompile or
restart Linux. You also don’t need to share your code with anyone else.

What eBPF provides to the Linux kernel is the extensibility to enable developers
to program the Linux kernel to quickly build intelligent or feature-rich
functions based on their business needs.

## Demo output example

The following output was capture from the *deploy.log* file generated
from the `vagrant up` execution.

<!-- markdownlint-disable MD010 -->
```bash
17:37:01 - INFO: Ping original service
64 bytes from 10.0.2.88: icmp_seq=1 ttl=64 time=0.314 ms
64 bytes from 10.0.2.88: icmp_seq=2 ttl=64 time=0.100 ms
64 bytes from 10.0.2.88: icmp_seq=3 ttl=64 time=0.314 ms
90e73714e2c9bd1b65606397f1c404903214c10965911fbfdb80cf36617a457f

17:37:05 - INFO: Ping bypass service
64 bytes from 172.80.0.2: icmp_seq=1 ttl=64 time=0.202 ms
64 bytes from 172.80.0.2: icmp_seq=2 ttl=64 time=0.105 ms
64 bytes from 172.80.0.2: icmp_seq=3 ttl=64 time=0.474 ms

17:37:07 - INFO: Bypass logs
Ready
b'           <...>-15142   [000] .Ns1   162.206663: 0: [tc_pingpong] ingress got packet'
b'           <...>-15142   [000] .Ns1   162.206703: 0: [tc_pingpong] ICMP request for 20050ac type 8'

17:37:07 - INFO: Trace events difference
	net:net_dev_queue:dev=docker0 
	net:net_dev_queue:dev=eth0 
	net:net_dev_queue:dev=veth8d5c57a 
	net:net_dev_start_xmit:dev=docker0 queue_mapping=0 
	net:net_dev_start_xmit:dev=eth0 queue_mapping=0 
	net:net_dev_start_xmit:dev=veth8d5c57a queue_mapping=0 
	net:net_dev_xmit:dev=docker0 
	net:net_dev_xmit:dev=eth0 
	net:net_dev_xmit:dev=veth8d5c57a 
	net:netif_receive_skb:dev=docker0 
	net:netif_receive_skb:dev=eth0 
	net:netif_receive_skb:dev=veth8d5c57a 
	net:netif_receive_skb_entry:dev=docker0 
	net:netif_receive_skb_exit:ret=0
	net:netif_rx:dev=eth0 
	net:netif_rx:dev=veth8d5c57a 
	net:netif_rx_entry:dev=eth0 
	net:netif_rx_entry:dev=veth8d5c57a 
	net:netif_rx_exit:ret=0
bypass
```
