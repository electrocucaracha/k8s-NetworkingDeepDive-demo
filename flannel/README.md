# Flannel CNI

Flannel is a simple and easy way to configure a layer 3 network fabric designed
for Kubernetes.

Flannel runs a small, single binary agent called flanneld on each host, and is
responsible for allocating a subnet lease to each host out of a larger,
preconfigured address space. Flannel uses either the Kubernetes API or etcd
directly to store the network configuration, the allocated subnets, and any
auxiliary data (such as the host's public IP). Packets are forwarded using one
of several backend mechanisms including VXLAN and various cloud integrations.

## NAT table rules

The following diagrams were created with [iptables-vis](https://github.com/Nudin/iptable_vis)
tool and pretend to clarify the rules created by Kubernetes components:

### Controller node

![k8s-control-plane](../img/controller.svg)

### Worker node

![k8s-worker](../img/worker.svg)

## Demo output example

The following output was capture from the _deploy.log_ file generated
from the `vagrant up` execution.

<!-- markdownlint-disable MD010 -->

```bash

21:55:17 - INFO: Cluster info:
name                podCIDR         InternalIP
k8s-control-plane   10.244.0.0/24   172.80.0.2
k8s-worker          10.244.2.0/24   172.80.0.4
k8s-worker2         10.244.1.0/24   172.80.0.3
name                                        podIP        nodeName
kube-flannel-ds-4jxw5                       172.80.0.2   k8s-control-plane
kube-flannel-ds-wn6ms                       172.80.0.3   k8s-worker2
kube-flannel-ds-wnd6g                       172.80.0.4   k8s-worker
coredns-7db6d8ff4d-44kzb                    <none>       k8s-worker
coredns-7db6d8ff4d-8dz87                    <none>       k8s-worker
etcd-k8s-control-plane                      172.80.0.2   k8s-control-plane
kube-apiserver-k8s-control-plane            172.80.0.2   k8s-control-plane
kube-controller-manager-k8s-control-plane   172.80.0.2   k8s-control-plane
kube-proxy-h4jhg                            172.80.0.3   k8s-worker2
kube-proxy-jcljq                            172.80.0.2   k8s-control-plane
kube-proxy-n8m6b                            172.80.0.4   k8s-worker
kube-scheduler-k8s-control-plane            172.80.0.2   k8s-control-plane
local-path-provisioner-988d74bc-krnhm       <none>       k8s-worker
=== k8s-worker Worker node info ===

21:55:18 - INFO: Flannel dynamic configuration
Creating debugging pod node-debugger-k8s-worker-r4l7p with container debugger on node k8s-worker.
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.2.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true

21:55:20 - INFO: Network IPv4 addresses
Creating debugging pod node-debugger-k8s-worker-dxlt7 with container debugger on node k8s-worker.
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: kube-ipvs0: <BROADCAST,NOARP> mtu 1500 qdisc noop state DOWN group default
    inet 10.96.0.10/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
    inet 10.96.0.1/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
3: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default
    inet 10.244.2.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
12: eth0@if13: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default  link-netnsid 0
    inet 172.80.0.4/24 brd 172.80.0.255 scope global eth0
       valid_lft forever preferred_lft forever

21:55:22 - INFO: VXLAN network devices
Creating debugging pod node-debugger-k8s-worker-58vmx with container debugger on node k8s-worker.
3: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default
    link/ether a6:c0:b3:5f:86:71 brd ff:ff:ff:ff:ff:ff promiscuity 0 minmtu 68 maxmtu 65535
    vxlan id 1 local 172.80.0.4 dev eth0 srcport 0 0 dstport 8472 nolearning ttl auto ageing 300 udpcsum noudp6zerocsumtx noudp6zerocsumrx addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535

21:55:24 - INFO: Network routes
Creating debugging pod node-debugger-k8s-worker-sdbd7 with container debugger on node k8s-worker.
default via 172.80.0.1 dev eth0
10.244.0.0/24 via 10.244.0.0 dev flannel.1 onlink
10.244.1.0/24 via 10.244.1.0 dev flannel.1 onlink
172.80.0.0/24 dev eth0 proto kernel scope link src 172.80.0.4

21:55:25 - INFO: ARP cache entries
Creating debugging pod node-debugger-k8s-worker-js45w with container debugger on node k8s-worker.
10.244.0.0 dev flannel.1 lladdr e6:7d:c5:e2:80:1a PERMANENT
10.244.1.0 dev flannel.1 lladdr 3a:bb:55:60:be:4e PERMANENT
172.80.0.2 dev eth0 lladdr 02:42:ac:50:00:02 REACHABLE
=== k8s-worker2 Worker node info ===

21:55:26 - INFO: Flannel dynamic configuration
Creating debugging pod node-debugger-k8s-worker2-vz26x with container debugger on node k8s-worker2.
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.1.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true

21:55:27 - INFO: Network IPv4 addresses
Creating debugging pod node-debugger-k8s-worker2-gnwvw with container debugger on node k8s-worker2.
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: kube-ipvs0: <BROADCAST,NOARP> mtu 1500 qdisc noop state DOWN group default
    inet 10.96.0.10/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
    inet 10.96.0.1/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
3: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default
    inet 10.244.1.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
10: eth0@if11: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default  link-netnsid 0
    inet 172.80.0.3/24 brd 172.80.0.255 scope global eth0
       valid_lft forever preferred_lft forever

21:55:28 - INFO: VXLAN network devices
Creating debugging pod node-debugger-k8s-worker2-fkzfn with container debugger on node k8s-worker2.
3: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default
    link/ether 3a:bb:55:60:be:4e brd ff:ff:ff:ff:ff:ff promiscuity 0 minmtu 68 maxmtu 65535
    vxlan id 1 local 172.80.0.3 dev eth0 srcport 0 0 dstport 8472 nolearning ttl auto ageing 300 udpcsum noudp6zerocsumtx noudp6zerocsumrx addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535

21:55:29 - INFO: Network routes
Creating debugging pod node-debugger-k8s-worker2-hhbrn with container debugger on node k8s-worker2.
default via 172.80.0.1 dev eth0
10.244.0.0/24 via 10.244.0.0 dev flannel.1 onlink
10.244.2.0/24 via 10.244.2.0 dev flannel.1 onlink
172.80.0.0/24 dev eth0 proto kernel scope link src 172.80.0.3

21:55:31 - INFO: ARP cache entries
Creating debugging pod node-debugger-k8s-worker2-l2hw2 with container debugger on node k8s-worker2.
10.244.0.0 dev flannel.1 lladdr e6:7d:c5:e2:80:1a PERMANENT
10.244.2.0 dev flannel.1 lladdr a6:c0:b3:5f:86:71 PERMANENT
172.80.0.2 dev eth0 lladdr 02:42:ac:50:00:02 REACHABLE

21:55:32 - INFO: Pods creation

21:55:35 - INFO: Traffic verification
PING 10.244.1.2 (10.244.1.2): 56 data bytes
64 bytes from 10.244.1.2: seq=0 ttl=62 time=0.199 ms
21:55:35.811444 IP (tos 0x0, ttl 64, id 46558, offset 0, flags [DF], proto ICMP (1), length 84)
    10.244.2.5 > 10.244.1.2: ICMP echo request, id 1, seq 1, length 64
21:55:35.811712 IP (tos 0x0, ttl 62, id 47195, offset 0, flags [none], proto ICMP (1), length 84)
    10.244.1.2 > 10.244.2.5: ICMP echo reply, id 1, seq 1, length 64
Frame 2: 98 bytes on wire (784 bits), 98 bytes captured (784 bits) on interface veth89403509, id 0
    Section number: 1
    Interface id: 0 (veth89403509)
        Interface name: veth89403509
    Encapsulation type: Ethernet (1)
    Arrival Time: Oct  2, 2024 21:55:37.812208493 UTC
    [Time shift for this packet: 0.000000000 seconds]
    Epoch Time: 1727906137.812208493 seconds
    [Time delta from previous captured frame: 0.628168251 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 0.628168251 seconds]
    Frame Number: 2
    Frame Length: 98 bytes (784 bits)
    Capture Length: 98 bytes (784 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:icmp:data]
Ethernet II, Src: da:aa:97:17:c9:b4 (da:aa:97:17:c9:b4), Dst: a6:ba:4b:37:26:7e (a6:ba:4b:37:26:7e)
    Destination: a6:ba:4b:37:26:7e (a6:ba:4b:37:26:7e)
        Address: a6:ba:4b:37:26:7e (a6:ba:4b:37:26:7e)
        .... ..1. .... .... .... .... = LG bit: Locally administered address (this is NOT the factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: da:aa:97:17:c9:b4 (da:aa:97:17:c9:b4)
        Address: da:aa:97:17:c9:b4 (da:aa:97:17:c9:b4)
        .... ..1. .... .... .... .... = LG bit: Locally administered address (this is NOT the factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
Internet Protocol Version 4, Src: 10.244.2.5, Dst: 10.244.1.2
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x00 (DSCP: CS0, ECN: Not-ECT)
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..00 = Explicit Congestion Notification: Not ECN-Capable Transport (0)
    Total Length: 84
    Identification: 0xb6ec (46828)
    010. .... = Flags: 0x2, Don't fragment
        0... .... = Reserved bit: Not set
        .1.. .... = Don't fragment: Set
        ..0. .... = More fragments: Not set
    ...0 0000 0000 0000 = Fragment Offset: 0
    Time to Live: 64
    Protocol: ICMP (1)
    Header Checksum: 0x6ace [validation disabled]
    [Header checksum status: Unverified]
    Source Address: 10.244.2.5
    Destination Address: 10.244.1.2
Internet Control Message Protocol
    Type: 8 (Echo (ping) request)
    Code: 0
    Checksum: 0xc529 [correct]
    [Checksum Status: Good]
    Identifier (BE): 1 (0x0001)
    Identifier (LE): 256 (0x0100)
    Sequence Number (BE): 3 (0x0003)
    Sequence Number (LE): 768 (0x0300)
    Data (56 bytes)

0000  c0 c1 72 10 00 00 00 00 00 00 00 00 00 00 00 00   ..r.............
0010  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   ................
0020  00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00   ................
0030  00 00 00 00 00 00 00 00                           ........
        Data: c0c172100000000000000000000000000000000000000000000000000000000000000000…
        [Length: 56]


21:55:37 - INFO: Workers status after Pods creation
=== k8s-worker Worker node info ===

21:55:37 - INFO: Last reserved IP address allocated by host-local
Creating debugging pod node-debugger-k8s-worker-tz2vq with container debugger on node k8s-worker.
10.244.2.5
21:55:39 - INFO: Virtual Ethernet network devices connected to cni0
5: veth93549b9a@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default
    link/ether ee:cc:31:1a:74:ec brd ff:ff:ff:ff:ff:ff link-netns cni-39f9a178-7d01-7d05-3b67-7b515576e286
6: vethc6e69f5f@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default
    link/ether d2:92:0c:92:e7:42 brd ff:ff:ff:ff:ff:ff link-netns cni-4f5e1acc-c367-eaad-a9e2-2a92125c65d1
7: veth48601bbf@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default
    link/ether ee:cd:3f:72:20:08 brd ff:ff:ff:ff:ff:ff link-netns cni-492be435-a2d4-cda3-767e-dcd017c590ec
8: veth89403509@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default
    link/ether 06:84:28:90:90:01 brd ff:ff:ff:ff:ff:ff link-netns cni-acb2e9e1-b3d5-793e-61d0-9defb052255a

21:55:40 - INFO: Bridge network devices
Creating debugging pod node-debugger-k8s-worker-znwpx with container debugger on node k8s-worker.
bridge name	bridge id		STP enabled	interfaces
cni0		8000.a6ba4b37267e	no		veth48601bbf
							veth89403509
							veth93549b9a
							vethc6e69f5f

21:55:42 - INFO: cni0 network routes
10.244.2.0/24 dev cni0 proto kernel scope link src 10.244.2.1
=== k8s-worker2 Worker node info ===

21:55:44 - INFO: Last reserved IP address allocated by host-local
Creating debugging pod node-debugger-k8s-worker2-698p9 with container debugger on node k8s-worker2.
10.244.1.2
21:55:46 - INFO: Virtual Ethernet network devices connected to cni0
5: veth4bea4427@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default
    link/ether 6e:aa:14:e4:6a:8f brd ff:ff:ff:ff:ff:ff link-netns cni-6dac480a-dade-afc0-f281-72bff90f6d4f

21:55:47 - INFO: Bridge network devices
Creating debugging pod node-debugger-k8s-worker2-lf82l with container debugger on node k8s-worker2.
bridge name	bridge id		STP enabled	interfaces
cni0		8000.ee6a517b0372	no		veth4bea4427

21:55:48 - INFO: cni0 network routes
10.244.1.0/24 dev cni0 proto kernel scope link src 10.244.1.1
=== k8s-worker Worker node info ===

21:55:49 - INFO: MAC addresses learned by cni0
Creating debugging pod node-debugger-k8s-worker-wq749 with container debugger on node k8s-worker.
port no	mac addr		is local?	ageing timer
  4	06:84:28:90:90:01	yes		   0.00
  4	06:84:28:90:90:01	yes		   0.00
  2	2a:d3:c7:19:08:4e	no		   7.42
  1	be:ae:0f:3b:2a:eb	no		   4.42
  3	c2:ef:2d:98:8a:9e	no		   4.42
  2	d2:92:0c:92:e7:42	yes		   0.00
  2	d2:92:0c:92:e7:42	yes		   0.00
  4	da:aa:97:17:c9:b4	no		   0.39
  1	ee:cc:31:1a:74:ec	yes		   0.00
  1	ee:cc:31:1a:74:ec	yes		   0.00
  3	ee:cd:3f:72:20:08	yes		   0.00
  3	ee:cd:3f:72:20:08	yes		   0.00

21:55:50 - INFO: ARP cache entries to pinghost pod
Creating debugging pod node-debugger-k8s-worker-mjg8n with container debugger on node k8s-worker.
Error: any valid prefix is expected rather than "$(ip route get 10.244.1.2 | grep flannel.1 | awk '{print $3}')".

21:55:52 - INFO: Forwarding Database entries of flannel.1
Creating debugging pod node-debugger-k8s-worker-zsgmz with container debugger on node k8s-worker.
e6:7d:c5:e2:80:1a dst 172.80.0.2 self permanent
3a:bb:55:60:be:4e dst 172.80.0.3 self permanent
=== k8s-worker2 Worker node info ===

21:55:54 - INFO: Network device details of flannel.1
Creating debugging pod node-debugger-k8s-worker2-mnjmp with container debugger on node k8s-worker2.
3: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default
    link/ether 3a:bb:55:60:be:4e brd ff:ff:ff:ff:ff:ff promiscuity 0 minmtu 68 maxmtu 65535
    vxlan id 1 local 172.80.0.3 dev eth0 srcport 0 0 dstport 8472 nolearning ttl auto ageing 300 udpcsum noudp6zerocsumtx noudp6zerocsumrx addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535

21:55:56 - INFO: Flannel's VTEP MAC address stored into Annotations
{"VNI":1,"VtepMAC":"3a:bb:55:60:be:4e"}
21:55:56 - INFO: Flannel's Public IP address stored into Annotations
172.80.0.3
```
