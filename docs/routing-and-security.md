# Route tables and security groups (design reference)

## Route tables (after peering)
**ewb-rt-a-public** (assoc. ewb-a-public)
| Destination | Target | Purpose |
|---|---|---|
| 10.10.0.0/16 | local | Bastion to App-A |
| 0.0.0.0/0 | ewb-igw-a | Bastion internet access |
| 10.20.0.0/16 | pcx (ewb-a-b-peer) | Bastion SSH to App-B |

**ewb-rt-a-private** (assoc. ewb-a-private)
| Destination | Target | Purpose |
|---|---|---|
| 10.10.0.0/16 | local | VPC A |
| 10.20.0.0/16 | pcx | App-A to VPC B |

**ewb-rt-b-private** (assoc. ewb-b-private)
| Destination | Target | Purpose |
|---|---|---|
| 10.20.0.0/16 | local | VPC B |
| 10.10.0.0/16 | pcx | Return path to VPC A |

## Security group inbound rules
| Group | Type / port | Source |
|---|---|---|
| ewb-sg-bastion | SSH TCP 22 | your public IPv4 /32 |
| ewb-sg-app-a | SSH TCP 22 | 10.10.1.10/32 (bastion) |
| ewb-sg-app-a | ICMP echo request (type 8, code 0) | 10.20.1.10/32 (App-B) |
| ewb-sg-app-b | SSH TCP 22 | 10.10.1.10/32 (bastion) |
| ewb-sg-app-b | ICMP echo request (type 8, code 0) | 10.10.2.10/32 (App-A) |

Outbound: default allow-all. Security groups are stateful. Network ACLs: default allow-all.

## Concept notes (use these to prepare your viva answers in your own words)
1. **Return route**: packets from App-A reach App-B via the peering route, but App-B's replies need a route to 10.10.0.0/16 or they have nowhere to go. Routes are per direction.
2. **Bastion private IP as SSH source**: with ProxyJump the bastion opens its own SSH connection to App-B, so App-B sees the bastion's private IP 10.10.1.10 as the source, not your laptop.
3. **Active peering is not enough**: peering is only the link. Route tables must point to it and security groups must allow the traffic.
4. **No IGW sharing**: peering does not allow edge-to-edge routing, so VPC B cannot use VPC A's internet gateway. Peering is also non-transitive.
