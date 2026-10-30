# Architecture

```mermaid
flowchart TB
    Laptop["Laptop<br/>local key + SSH config"] -->|"SSH / 22"| IGW["Internet gateway<br/>ewb-igw-a (attached to VPC A)"]

    subgraph VPCA["VPC A - ewb-vpc-a - 10.10.0.0/16"]
        direction TB
        PUB["Public subnet ewb-a-public 10.10.1.0/24<br/>ewb-bastion 10.10.1.10 + public IPv4"]
        PRIV_A["Private subnet ewb-a-private 10.10.2.0/24<br/>ewb-app-a 10.10.2.10 (no public IP)"]
        PUB -->|"SSH (local route)"| PRIV_A
    end

    subgraph VPCB["VPC B - ewb-vpc-b - 10.20.0.0/16 (no internet gateway)"]
        PRIV_B["Private subnet ewb-b-private 10.20.1.0/24<br/>ewb-app-b 10.20.1.10 (no public IP)"]
    end

    IGW --> PUB
    PRIV_A <-->|"VPC peering ewb-a-b-peer<br/>ICMP echo (private IPs)"| PRIV_B
    PUB -->|"SSH via peering (ProxyJump)"| PRIV_B
```

- Administration: laptop > bastion > App-A or App-B (SSH ProxyJump).
- Project traffic: App-A <> App-B over private IPs through the peering connection.
- Peering does not give VPC B internet access through VPC A (no transitive routing, no edge-to-edge routing via IGW).

## Address plan
| Resource | Where | CIDR / address |
|---|---|---|
| ewb-vpc-a | VPC A | 10.10.0.0/16 |
| ewb-a-public | VPC A | 10.10.1.0/24 |
| ewb-a-private | VPC A | 10.10.2.0/24 |
| ewb-vpc-b | VPC B | 10.20.0.0/16 |
| ewb-b-private | VPC B | 10.20.1.0/24 |
| ewb-bastion | ewb-a-public | 10.10.1.10 + public IPv4 |
| ewb-app-a | ewb-a-private | 10.10.2.10, no public IP |
| ewb-app-b | ewb-b-private | 10.20.1.10, no public IP |

The two VPC CIDRs do not overlap, which is a requirement for peering.
