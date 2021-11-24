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
23:39:16 - INFO: Using Round Robin scheduling algorithm

23:39:16 - INFO: Generating HTTP traffic (Host to IPVS Service)
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

23:39:21 - INFO: Increase pod1 weight
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  1.2.3.4:80 wrr
  -> 172.80.0.2:80                Masq    3      0          2         
  -> 172.80.0.3:80                Masq    1      0          2         
  -> 172.80.0.4:80                Masq    1      0          2         

23:39:21 - INFO: Using Weighted Round Robin scheduling algorithm

23:39:21 - INFO: Generating HTTP traffic (Host to IPVS Service)
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

23:39:26 - INFO: Validating communication between Pod and ClusterIP

23:39:26 - INFO: Generating HTTP traffic (Pod to IPVS Service)






IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                         12       60       60     4068     4128
  -> 172.80.0.2:80                       6       30       30     2034     2064
  -> 172.80.0.3:80                       3       15       15     1017     1032
  -> 172.80.0.4:80                       3       15       15     1017     1032

23:39:37 - INFO: Creating IPVS dummy interface

23:39:37 - INFO: Generating HTTP traffic (Pod to IPVS Service)
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

23:39:44 - INFO: Enabling Hairpin connections

23:39:44 - INFO: Generating HTTP traffic (Pod to IPVS Service)
This is service #3
This is service #2
This is service #1
This is service #3
This is service #2
This is service #1
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                         24      110      110     7474     7568
  -> 172.80.0.2:80                      10       41       40     2780     2752
  -> 172.80.0.3:80                       7       34       35     2321     2408
  -> 172.80.0.4:80                       7       35       35     2373     2408
```
