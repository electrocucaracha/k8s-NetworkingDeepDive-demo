# IP Virtual Server

IPVS (IP Virtual Server) implements transport-layer load balancing, usually
called Layer 4 LAN switching, as part of the Linux kernel. IPVS running on a
host acts as a load balancer at the front of a cluster of real servers, it can
direct requests for TCP/UDP based services to the real servers, and makes
services of the real servers to appear as a virtual service on a single IP
address.

The scripts of this folder compares two scheduling algorithms supported by IPVS

- Round Robin - Distributes jobs equally amongst the available real server
- Weighted Round Robin - Assigns jobs to real servers proportionally to there
real servers’ weight. Servers with higher weights receive new jobs first and get
more jobs than servers with lower weights. Servers with equal weights get an
equal distribution of new jobs.

## Demo output example

The following output was capture from the _deploy.log_ file generated
from the `vagrant up` execution.

```bash
21:23:38 - INFO: Using Round Robin scheduling algorithm

21:23:38 - INFO: Generating HTTP traffic
This is service #3
This is service #2
This is service #1
This is service #3
This is service #2
This is service #1
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                          6       30       30     2034     2064
  -> 172.80.0.2:80                       2       10       10      678      688
  -> 172.80.0.3:80                       2       10       10      678      688
  -> 172.80.0.4:80                       2       10       10      678      688

21:23:43 - INFO: Increase pod1 weight
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  1.2.3.4:80 wrr
  -> 172.80.0.2:80                Masq    3      0          2         
  -> 172.80.0.3:80                Masq    1      0          2         
  -> 172.80.0.4:80                Masq    1      0          2         

21:23:43 - INFO: Using Weighted Round Robin scheduling algorithm

21:23:43 - INFO: Generating HTTP traffic
This is service #1
This is service #1
This is service #3
This is service #2
This is service #1
This is service #1
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                         12       60       60     4068     4128
  -> 172.80.0.2:80                       6       30       30     2034     2064
  -> 172.80.0.3:80                       3       15       15     1017     1032
  -> 172.80.0.4:80                       3       15       15     1017     1032

21:23:48 - INFO: Validating communication between Pod and ClusterIP

21:23:48 - INFO: Generating HTTP traffic






IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                         12       60       60     4068     4128
  -> 172.80.0.2:80                       6       30       30     2034     2064
  -> 172.80.0.3:80                       3       15       15     1017     1032
  -> 172.80.0.4:80                       3       15       15     1017     1032

21:24:00 - INFO: Creating IPVS dummy interface
net.bridge.bridge-nf-call-iptables = 1

21:24:00 - INFO: Generating HTTP traffic
This is service #3
This is service #2

This is service #3
This is service #2

IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                         18       82       80     5544     5504
  -> 172.80.0.2:80                       8       32       30     2154     2064
  -> 172.80.0.3:80                       5       25       25     1695     1720
  -> 172.80.0.4:80                       5       25       25     1695     1720

21:24:07 - INFO: Enabiling Hairpin connections
net.ipv4.vs.conntrack = 1

21:24:07 - INFO: Generating HTTP traffic
This is service #3
This is service #2
This is service #1
This is service #3
This is service #2
This is service #1
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                         24      111      110     7526     7568
  -> 172.80.0.2:80                      10       42       40     2832     2752
  -> 172.80.0.3:80                       7       35       35     2373     2408
  -> 172.80.0.4:80                       7       34       35     2321     2408
```
