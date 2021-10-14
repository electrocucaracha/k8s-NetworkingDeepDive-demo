# Flannel CNI

Flannel is a simple and easy way to configure a layer 3 network fabric designed
for Kubernetes.

Flannel runs a small, single binary agent called flanneld on each host, and is
responsible for allocating a subnet lease to each host out of a larger,
preconfigured address space. Flannel uses either the Kubernetes API or etcd
directly to store the network configuration, the allocated subnets, and any
auxiliary data (such as the host's public IP). Packets are forwarded using one
of several backend mechanisms including VXLAN and various cloud integrations.

## Demo output example

The following output was capture from the _deploy.log_ file generated
from the `vagrant up` execution.

<!-- markdownlint-disable MD010 -->
```bash
20:00:34 - INFO: Cluster info:
name                podCIDR         InternalIP
k8s-control-plane   10.244.0.0/24   172.80.1.4
k8s-worker          10.244.2.0/24   172.80.1.3
k8s-worker2         10.244.1.0/24   172.80.1.2
name                                        podIP        nodeName
coredns-78fcd69978-292zj                    10.244.0.3   k8s-control-plane
coredns-78fcd69978-2fsgm                    10.244.0.2   k8s-control-plane
etcd-k8s-control-plane                      172.80.1.4   k8s-control-plane
kube-apiserver-k8s-control-plane            172.80.1.4   k8s-control-plane
kube-controller-manager-k8s-control-plane   172.80.1.4   k8s-control-plane
kube-flannel-ds-6wzq8                       172.80.1.4   k8s-control-plane
kube-flannel-ds-htngq                       172.80.1.2   k8s-worker2
kube-flannel-ds-rbng4                       172.80.1.3   k8s-worker
kube-proxy-mkf6n                            172.80.1.4   k8s-control-plane
kube-proxy-x5pc2                            172.80.1.3   k8s-worker
kube-proxy-xvvk5                            172.80.1.2   k8s-worker2
kube-scheduler-k8s-control-plane            172.80.1.4   k8s-control-plane
local-path-provisioner-85494db59d-ckz8r     10.244.0.4   k8s-control-plane
=== k8s-worker Worker node info ===

20:00:34 - INFO: Flannel dynamic configuration
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.2.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true

20:00:34 - INFO: Network IPv4 addresses
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: kube-ipvs0: <BROADCAST,NOARP> mtu 1500 qdisc noop state DOWN group default 
    inet 10.96.0.10/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
    inet 10.96.0.1/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
3: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default 
    inet 10.244.2.0/32 brd 10.244.2.0 scope global flannel.1
       valid_lft forever preferred_lft forever
8: eth0@if9: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default  link-netnsid 0
    inet 172.80.1.3/24 brd 172.80.1.255 scope global eth0
       valid_lft forever preferred_lft forever

20:00:34 - INFO: VXLAN network devices
3: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default 
    link/ether fe:f8:9b:6c:10:59 brd ff:ff:ff:ff:ff:ff promiscuity 0 minmtu 68 maxmtu 65535 
    vxlan id 1 local 172.80.1.3 dev eth0 srcport 0 0 dstport 8472 nolearning ttl auto ageing 300 udpcsum noudp6zerocsumtx noudp6zerocsumrx addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535 

20:00:34 - INFO: Network routes
default via 172.80.1.1 dev eth0 
10.244.0.0/24 via 10.244.0.0 dev flannel.1 onlink 
10.244.1.0/24 via 10.244.1.0 dev flannel.1 onlink 
172.80.1.0/24 dev eth0 proto kernel scope link src 172.80.1.3 

20:00:34 - INFO: ARP cache entries
172.80.1.4 dev eth0 lladdr 02:42:ac:50:01:04 REACHABLE
10.244.0.0 dev flannel.1 lladdr d2:32:df:ad:77:2f PERMANENT
172.80.1.1 dev eth0 lladdr 02:42:bc:ce:90:82 REACHABLE
10.244.1.0 dev flannel.1 lladdr da:37:d5:a4:a2:f0 PERMANENT
=== k8s-worker2 Worker node info ===

20:00:34 - INFO: Flannel dynamic configuration
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.1.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true

20:00:34 - INFO: Network IPv4 addresses
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: kube-ipvs0: <BROADCAST,NOARP> mtu 1500 qdisc noop state DOWN group default 
    inet 10.96.0.1/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
    inet 10.96.0.10/32 scope global kube-ipvs0
       valid_lft forever preferred_lft forever
3: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default 
    inet 10.244.1.0/32 brd 10.244.1.0 scope global flannel.1
       valid_lft forever preferred_lft forever
6: eth0@if7: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default  link-netnsid 0
    inet 172.80.1.2/24 brd 172.80.1.255 scope global eth0
       valid_lft forever preferred_lft forever

20:00:34 - INFO: VXLAN network devices
3: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default 
    link/ether da:37:d5:a4:a2:f0 brd ff:ff:ff:ff:ff:ff promiscuity 0 minmtu 68 maxmtu 65535 
    vxlan id 1 local 172.80.1.2 dev eth0 srcport 0 0 dstport 8472 nolearning ttl auto ageing 300 udpcsum noudp6zerocsumtx noudp6zerocsumrx addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535 

20:00:34 - INFO: Network routes
default via 172.80.1.1 dev eth0 
10.244.0.0/24 via 10.244.0.0 dev flannel.1 onlink 
10.244.2.0/24 via 10.244.2.0 dev flannel.1 onlink 
172.80.1.0/24 dev eth0 proto kernel scope link src 172.80.1.2 

20:00:34 - INFO: ARP cache entries
172.80.1.4 dev eth0 lladdr 02:42:ac:50:01:04 REACHABLE
10.244.0.0 dev flannel.1 lladdr d2:32:df:ad:77:2f PERMANENT
10.244.2.0 dev flannel.1 lladdr fe:f8:9b:6c:10:59 PERMANENT
172.80.1.1 dev eth0 lladdr 02:42:bc:ce:90:82 REACHABLE

20:00:34 - INFO: Pods creation

20:00:37 - INFO: Traffic verification
PING 10.244.1.2 (10.244.1.2): 56 data bytes
64 bytes from 10.244.1.2: seq=0 ttl=62 time=0.581 ms
20:00:38.508169 IP (tos 0x0, ttl 64, id 11689, offset 0, flags [DF], proto ICMP (1), length 84)
    10.244.2.2 > 10.244.1.2: ICMP echo request, id 1, seq 1, length 64
20:00:38.508317 IP (tos 0x0, ttl 62, id 37089, offset 0, flags [none], proto ICMP (1), length 84)
    10.244.1.2 > 10.244.2.2: ICMP echo reply, id 1, seq 1, length 64

20:00:39 - INFO: Workers status after Pods creation
=== k8s-worker Worker node info ===

20:00:39 - INFO: Last reserved IP address allocated by host-local
10.244.2.2
20:00:39 - INFO: Virtual Ethernet network devices connected to cni0
5: veth2b05939f@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default 
    link/ether 1a:f1:12:04:04:c8 brd ff:ff:ff:ff:ff:ff link-netns cni-d912184a-3b41-f275-8d4b-3dd3b8c4e059

20:00:39 - INFO: Bridge network devices
bridge name	bridge id		STP enabled	interfaces
cni0		8000.5e1818d56eea	no		veth2b05939f

20:00:39 - INFO: cni0 network routes
10.244.2.0/24 dev cni0 proto kernel scope link src 10.244.2.1 
=== k8s-worker2 Worker node info ===

20:00:40 - INFO: Last reserved IP address allocated by host-local
10.244.1.2
20:00:40 - INFO: Virtual Ethernet network devices connected to cni0
5: vethb55f6598@if2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP mode DEFAULT group default 
    link/ether 6a:d6:8c:4b:a6:04 brd ff:ff:ff:ff:ff:ff link-netns cni-91ac823d-cbb7-2b85-6ab6-9cacf86c1592

20:00:40 - INFO: Bridge network devices
bridge name	bridge id		STP enabled	interfaces
cni0		8000.622009fcc300	no		vethb55f6598

20:00:40 - INFO: cni0 network routes
10.244.1.0/24 dev cni0 proto kernel scope link src 10.244.1.1 
=== k8s-worker Worker node info ===

20:00:40 - INFO: MAC addresses learned by cni0
port no	mac addr		is local?	ageing timer
  1	1a:f1:12:04:04:c8	yes		   0.00
  1	1a:f1:12:04:04:c8	yes		   0.00
  1	ce:50:fa:0a:d3:e2	no		   0.90

20:00:40 - INFO: ARP cache entries to pinghost pod
10.244.1.0 dev flannel.1 lladdr da:37:d5:a4:a2:f0 PERMANENT

20:00:40 - INFO: Forwarding Database entries of flannel.1
d2:32:df:ad:77:2f dst 172.80.1.4 self permanent
da:37:d5:a4:a2:f0 dst 172.80.1.2 self permanent
=== k8s-worker2 Worker node info ===

20:00:40 - INFO: Network device details of flannel.1
3: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN mode DEFAULT group default 
    link/ether da:37:d5:a4:a2:f0 brd ff:ff:ff:ff:ff:ff promiscuity 0 minmtu 68 maxmtu 65535 
    vxlan id 1 local 172.80.1.2 dev eth0 srcport 0 0 dstport 8472 nolearning ttl auto ageing 300 udpcsum noudp6zerocsumtx noudp6zerocsumrx addrgenmode eui64 numtxqueues 1 numrxqueues 1 gso_max_size 65536 gso_max_segs 65535 

20:00:40 - INFO: Flannel's VTEP MAC address stored into Annotations
{"VNI":1,"VtepMAC":"da:37:d5:a4:a2:f0"}
20:00:40 - INFO: Flannel's Public IP address stored into Annotations
172.80.1.2
```
