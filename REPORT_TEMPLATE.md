# AWS VPC Peering — Project Report
**Name:** ______  **Batch:** ______  **Region:** ap-south-1  **Completed:** ______

## 1. Architecture and inventory
(Insert diagram. Paste `terraform output inventory` and private IPs.)

## 2. Subnets and route tables (Checkpoints 01 and 04)
Screenshots: subnet CIDRs; ewb-rt-a-public, ewb-rt-a-private, ewb-rt-b-private with subnet associations.

## 3. Peering (Checkpoint 03)
Screenshot: ewb-a-b-peer Active, both VPC IDs.

## 4. Security group inbound rules
Screenshots: ewb-sg-bastion, ewb-sg-app-a, ewb-sg-app-b.

## 5. Test evidence (label host / test / result)
- Baseline failure — evidence/baseline_*.txt
- Forward + reverse ping, App-B SSH, isolation — evidence/peered_*.txt
- Controlled ICMP failure and recovery — evidence/controlled_failure_*.txt

## 6. Forward path and return path (write in your own words)
...

## 7. Explain
1. Why is the return route needed?
2. Why is the App-B SSH source the bastion private IP?
3. Why does Active peering not guarantee a successful ping?
4. Can VPC B use VPC A's internet gateway over peering?

## 8. Cleanup evidence and what I learned
evidence/cleanup_*.txt + screenshots. Short note: ...
