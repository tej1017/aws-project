# Test plan (expected results are acceptance criteria, not results)

| Test | Where / command | Expected | Evidence file |
|---|---|---|---|
| 01 Baseline | App-A before peering: `ping -c 4 10.20.1.10` | No replies | `evidence/baseline_*.txt` |
| 02 Forward | App-A after routes: `ping -c 4 10.20.1.10` | 4 replies, 0% loss | `evidence/peered_*.txt` |
| 03 Reverse | App-B: `ping -c 4 10.10.2.10` | 4 replies, 0% loss | `evidence/peered_*.txt` |
| 04 Private SSH | Laptop: `ssh ewb-app-b` | Shell on App-B via bastion | `evidence/peered_*.txt` |
| 05 Isolation | EC2 details of App-A / App-B | No public IPv4 | `evidence/peered_*.txt` |
| 06 Controlled failure | remove then restore App-B ICMP rule | fail then recover | `evidence/controlled_failure_*.txt` |

Replace this table's expectations with your actual observed results in your PDF report.
