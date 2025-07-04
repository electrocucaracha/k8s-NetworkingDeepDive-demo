# Bash CNI

Container Network Interface (CNI) defines a network configuration format for
administrators. It contains directives for both the container runtime as well as
the plugins to consume. At plugin execution time, this configuration format is
interpreted by the runtime and transformed in to a form to be passed to the
plugins.

A CNI plugin must provide at least the following two things:

- Connectivity - Every Pod must have a NIC (`$CNI_IFNAME`) to communicate with
  anything outside of its own network namespace. Some local processes on the Node
  (e.g. kubelet) need to reach PodIP from the root network namespace (e.g. to
  perform health and readiness checks), hence the root NS connectivity
  requirement.

- Reachability - Pods from other Nodes can reach each other directly (without
  NAT).
  - Every Pod gets a unique IP from a PodCIDR range configured on the Node.
  - This range is assigned to the Node during kubelet bootstrapping phase.
  - Nodes are not aware of PodCIDRs assigned to other Nodes, allocations are
    normally managed by the controller-manager based on the `--cluster-cidr`
    configuration flag.

Kubernetes first creates a container(`$CNI_CONTAINERID`) without a network
interface and then calls a CNI plug-in. The plug-in configures container
networking and returns information about allocated network interfaces,
IP addresses, etc. The parameters that Kubernetes sends to a CNI plugin, as well
as the structure of the response must satisfy the CNI specification, but the
plug-in itself may do whatever it needs to do its job.

## Demo output example

The following output was capture from the _deploy.log_ file generated
from the `vagrant up` execution.

<!-- markdownlint-disable MD010 -->

```bash
pod/test created
pod/test condition met

21:13:32 - INFO: Getting the IP address assigned to the Pod
12: eth0@if11: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue qlen 1000
    link/ether 6a:4c:78:6a:e9:d7 brd ff:ff:ff:ff:ff:ff
    inet 10.244.0.5/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::684c:78ff:fe6a:e9d7/64 scope link
       valid_lft forever preferred_lft forever

21:13:29 - DEBUG: stdin: {"cniVersion":"0.3.1","name":"mynet","network":"10.244.0.0/16","subnet":"10.244.0.0/24","type":"bash-cni"}
21:13:29 - DEBUG: CNI envs: CNI_CONTAINERID=130d9e7a9b5505372e1db478bbf95f5bb46977939833d2568a849a214e7414dc
CNI_IFNAME=eth0
CNI_NETNS=/var/run/netns/cni-099e7256-f5fa-a0d2-9bdf-61829dc0aa4a
CNI_COMMAND=ADD
CNI_PATH=/opt/cni/bin
CNI_ARGS=K8S_POD_INFRA_CONTAINER_ID=130d9e7a9b5505372e1db478bbf95f5bb46977939833d2568a849a214e7414dc;K8S_POD_UID=3c435641-b262-438b-a4cf-4a8c77a4dfe5;IgnoreUnknown=1;K8S_POD_NAMESPACE=default;K8S_POD_NAME=test
21:13:29 - INFO: Discover IP addresses
21:13:29 - DEBUG: gw_ip: 10.244.0.1
21:13:29 - DEBUG: container_ip: 10.244.0.5
21:13:29 - INFO: Binding IP address
Device "tmpCEE8" does not exist.

21:13:29 - DEBUG: host_if_name: vethCEE8
21:13:29 - INFO: Connecting vethCEE8 to cni0
bridge name	bridge id		STP enabled	interfaces
cni0		8000.525b9233bb86	no		veth0932
							veth7ECA
							vethCEE8
							vethE51C

21:13:29 - INFO: Setting tmpCEE8 of 130d9e7a9b5505372e1db478bbf95f5bb46977939833d2568a849a214e7414dc container
21:13:29 - DEBUG: sdtout: {
  "cniVersion": "0.3.1",
  "interfaces": [
    {
      "name": "eth0",
      "mac": "6a:4c:78:6a:e9:d7",
      "sandbox": "/var/run/netns/cni-099e7256-f5fa-a0d2-9bdf-61829dc0aa4a"
    }
  ],
  "ips": [
    {
      "version": "4",
      "address": "10.244.0.5/24",
      "gateway": "10.244.0.1",
      "interface": 0
    }
  ]
}
pod "test" deleted
```
