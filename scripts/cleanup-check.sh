#!/usr/bin/env bash
# Run AFTER `terraform destroy`. Lists anything still tagged Project=EWB-VPC-Peering.
set -uo pipefail
cd "$(dirname "$0")/.."
REGION=${1:-ap-south-1}
OUT="evidence/cleanup_$(date +%Y%m%d_%H%M%S).txt"
F="Name=tag:Project,Values=EWB-VPC-Peering"
{
echo "Cleanup check $(date -u +%FT%TZ) region=$REGION  (empty sections = good)"
echo "## Instances (not terminated)"; aws ec2 describe-instances --region $REGION --filters $F "Name=instance-state-name,Values=pending,running,stopping,stopped" --query 'Reservations[].Instances[].InstanceId' --output text
echo "## Volumes";   aws ec2 describe-volumes --region $REGION --filters $F --query 'Volumes[].VolumeId' --output text
echo "## VPCs";      aws ec2 describe-vpcs --region $REGION --filters $F --query 'Vpcs[].VpcId' --output text
echo "## Peering";   aws ec2 describe-vpc-peering-connections --region $REGION --filters $F "Name=status-code,Values=active,pending-acceptance,provisioning" --query 'VpcPeeringConnections[].VpcPeeringConnectionId' --output text
echo "## Elastic IPs"; aws ec2 describe-addresses --region $REGION --query 'Addresses[].PublicIp' --output text
echo "## Key pair ewb-lab"; aws ec2 describe-key-pairs --region $REGION --key-names ewb-lab 2>&1 | tail -1
} | tee "$OUT"
