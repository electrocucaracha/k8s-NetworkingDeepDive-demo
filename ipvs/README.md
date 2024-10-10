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
01:58:54 - INFO: Using Round Robin scheduling algorithm

01:58:54 - INFO: Generating HTTP traffic (Host to Service)
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

01:58:59 - INFO: Validating communication between Pod and ClusterIP

01:58:59 - INFO: Generating HTTP traffic (Namespace to Service)






IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                          6       30       30     2034     2064
  -> 172.80.0.2:80                       2       10       10      678      688
  -> 172.80.0.3:80                       2       10       10      678      688
  -> 172.80.0.4:80                       2       10       10      678      688

01:59:10 - INFO: Creating IPVS dummy interface

01:59:10 - INFO: Generating HTTP traffic (Namespace to Service)
This is service #3
This is service #2

This is service #3
This is service #2

IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                         12       52       50     3510     3440
  -> 172.80.0.2:80                       4       12       10      798      688
  -> 172.80.0.3:80                       4       20       20     1356     1376
  -> 172.80.0.4:80                       4       20       20     1356     1376

01:59:17 - INFO: Enabling Hairpin connections

01:59:17 - INFO: Generating HTTP traffic (Namespace to Service)
This is service #3
This is service #2
This is service #1
This is service #3
This is service #2
This is service #1
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                         18       82       80     5544     5504
  -> 172.80.0.2:80                       6       22       20     1476     1376
  -> 172.80.0.3:80                       6       30       30     2034     2064
  -> 172.80.0.4:80                       6       30       30     2034     2064

01:59:22 - INFO: Increase pod1 weight
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  1.2.3.4:80 wrr
  -> 172.80.0.2:80                Masq    3      2          4
  -> 172.80.0.3:80                Masq    1      0          6
  -> 172.80.0.4:80                Masq    1      0          6

01:59:22 - INFO: Using Weighted Round Robin scheduling algorithm

01:59:22 - INFO: Generating HTTP traffic (Host to Service)
This is service #1
This is service #1
This is service #3
This is service #2
This is service #1
This is service #1
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                         24      112      110     7578     7568
  -> 172.80.0.2:80                      10       42       40     2832     2752
  -> 172.80.0.3:80                       7       35       35     2373     2408
  -> 172.80.0.4:80                       7       35       35     2373     2408
```
