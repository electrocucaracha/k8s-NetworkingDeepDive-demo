# Pause containers

The [pause][1] container serves as the _parent container_ for all of the
containers in the Kubernetes pod. The pause container has two main
responsibilities:

1. Serves as the basis of Linux namespace sharing in the pod.
   - Allows containers to communicate directly using the localhost.
   - Allows the containers to share their inter-process communication (IPC)
     namespace with the other containers so they can communicate directly through
     shared-memory with other containers.
   - Allows containers to share their process ID (PID) namespace with other
     containers.

1. With PID (process ID) namespace sharing [enabled][3], it serves as PID 1
   for each pod and reaps zombie processes.

The scripts of this folder simulate the [Dockershim's RunPodSandbox
function][2] used by Kubelet as initial step for the Pod's creation.
Its goal is better understand this workflow and highlight the usage of
non-docker tools.

[1]: https://github.com/kubernetes-csi/driver-registrar/blob/master/vendor/k8s.io/kubernetes/build/pause/pause.c
[2]: https://github.com/kubernetes/kubernetes/blob/v1.20.4/pkg/kubelet/dockershim/docker_sandbox.go#L84-L205
[3]: https://kubernetes.io/docs/tasks/configure-pod-container/share-process-namespace/

## Demo output example

The following output was capture from the _deploy.log_ file generated
from the `vagrant up` execution.

```bash
23:49:29 - INFO: Pulling busybox image

23:49:33 - INFO: Network namespaces before container creation:
        NS TYPE NPROCS   PID USER       NETNSID NSFS COMMAND
4026531992 net       7  1052 vagrant unassigned      /lib/systemd/systemd --user

23:49:33 - INFO: Starting the test-container container...
23:49:33 - INFO: Processes list:
UID          PID    PPID  C STIME TTY          TIME CMD
vagrant     5412       1  0 23:49 ?        00:00:00 sh init.sh

23:49:33 - INFO: Container list
ID               PID         STATUS      BUNDLE                       CREATED                          OWNER
test-container   5412        running     /tmp/tmp.ie5WoPVZrW/bundle   2021-03-18T23:49:33.250824015Z   vagrant

23:49:33 - INFO: Network namespaces after container creation and before allocation:
        NS TYPE NPROCS   PID USER       NETNSID NSFS COMMAND
4026531992 net       7  1052 vagrant unassigned      /lib/systemd/systemd --user
4026532265 net       2  5412 vagrant unassigned      sh init.sh

23:49:33 - INFO: Network namespaces after allocation:
test-container

23:49:33 - INFO: Host Network state:
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:da:f6:f8 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.75/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 3521sec preferred_lft 3521sec
    inet6 fe80::5054:ff:feda:f6f8/64 scope link
       valid_lft forever preferred_lft forever

23:49:33 - INFO: Container Network state:
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever

23:49:33 - INFO: Adding network thru CNI tool:
{
    "cniVersion": "0.4.0",
    "interfaces": [
        {
            "name": "cni0",
            "mac": "ea:3c:01:a9:70:e5"
        },
        {
            "name": "veth1afd548b",
            "mac": "da:8a:60:1f:fc:6d"
        },
        {
            "name": "eth0",
            "mac": "c2:7a:59:5c:51:0e",
            "sandbox": "/var/run/netns/test-container"
        }
    ],
    ],
    "ips": [
        {
            "version": "4",
            "interface": 2,
            "address": "10.10.0.2/24",
            "gateway": "10.10.0.1"
        }
    ],
    "routes": [
        {
            "dst": "0.0.0.0/0",
            "gw": "10.10.0.1"
        }
    ],
    "dns": {}
}
23:49:33 - INFO: Host Network state:
test-container (id: 0)
        NS TYPE NPROCS   PID USER       NETNSID NSFS COMMAND
4026531992 net       7  1052 vagrant unassigned      /lib/systemd/systemd --user
4026532265 net       2  5412 vagrant          0      sh init.sh
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:da:f6:f8 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.75/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 3521sec preferred_lft 3521sec
    inet6 fe80::5054:ff:feda:f6f8/64 scope link
       valid_lft forever preferred_lft forever
3: cni0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether ea:3c:01:a9:70:e5 brd ff:ff:ff:ff:ff:ff
    inet 10.10.0.1/24 brd 10.10.0.255 scope global cni0
       valid_lft forever preferred_lft forever
4: veth1afd548b@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master cni0 state UP group default
    link/ether da:8a:60:1f:fc:6d brd ff:ff:ff:ff:ff:ff link-netns test-container
bridge name     bridge id               STP enabled     interfaces
cni0            8000.ea3c01a970e5       no              veth1afd548b
port no mac addr                is local?       ageing timer
  1     c2:7a:59:5c:51:0e       no                 0.05
  1     da:8a:60:1f:fc:6d       yes                0.00
  1     da:8a:60:1f:fc:6d       yes                0.00

23:49:33 - INFO: Container eth0 nic info:
3: eth0@if4: <BROADCAST,MULTICAST,UP,LOWER_UP,M-DOWN> mtu 1500 qdisc noqueue
    link/ether c2:7a:59:5c:51:0e brd ff:ff:ff:ff:ff:ff
    inet 10.10.0.2/24 brd 10.10.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::c07a:59ff:fe5c:510e/64 scope link tentative
       valid_lft forever preferred_lft forever

23:49:33 - INFO: Droping network thru CNI tool:

23:49:33 - INFO: Host Network state:
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:da:f6:f8 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.75/24 brd 10.0.2.255 scope global dynamic eth0
       valid_lft 3521sec preferred_lft 3521sec
    inet6 fe80::5054:ff:feda:f6f8/64 scope link
       valid_lft forever preferred_lft forever
3: cni0: <BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether ea:3c:01:a9:70:e5 brd ff:ff:ff:ff:ff:ff
    inet 10.10.0.1/24 brd 10.10.0.255 scope global cni0
       valid_lft forever preferred_lft forever
bridge name     bridge id               STP enabled     interfaces
cni0            8000.ea3c01a970e5       no
port no mac addr                is local?       ageing timer

23:49:33 - INFO: Container Network state:
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever

23:49:33 - INFO: Containers list:
ID               PID         STATUS      BUNDLE                       CREATED                          OWNER
test-container   5412        running     /tmp/tmp.ie5WoPVZrW/bundle   2021-03-18T23:49:33.250824015Z   vagrant

23:49:33 - INFO: Stopping test-container container
```
