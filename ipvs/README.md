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
17:29:38 - INFO: Using Round Robin scheduling algorithm
This is service #3
This is service #2
This is service #1
This is service #3
This is service #2
This is service #1
This is service #3
This is service #2
This is service #1
This is service #3
This is service #2
This is service #1
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                         12       60       60     4068     4128
  -> 172.80.0.2:80                       4       20       20     1356     1376
  -> 172.80.0.3:80                       4       20       20     1356     1376
  -> 172.80.0.4:80                       4       20       20     1356     1376

17:29:43 - INFO: Increase svc1 weight
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  1.2.3.4:80 rr
  -> 172.80.0.2:80                Masq    3      0          4         
  -> 172.80.0.3:80                Masq    1      0          4         
  -> 172.80.0.4:80                Masq    1      0          4         

17:29:43 - INFO: Using Weighted Round Robin scheduling algorithm
This is service #1
This is service #1
This is service #3
This is service #2
This is service #1
This is service #1
This is service #1
This is service #3
This is service #2
This is service #1
This is service #1
This is service #1
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port               Conns   InPkts  OutPkts  InBytes OutBytes
  -> RemoteAddress:Port
TCP  1.2.3.4:80                         24      120      120     8136     8256
  -> 172.80.0.2:80                      12       60       60     4068     4128
  -> 172.80.0.3:80                       6       30       30     2034     2064
  -> 172.80.0.4:80                       6       30       30     2034     2064
```
