#!/usr/bin/env bash
# Captures real inventory, routes, subnet associations, peering and SG rules into evidence/.
# Run after the peering phase (and optionally after baseline).
set -uo pipefail
cd "$(dirname "$0")/.."
REGION=$(terraform -chdir=terraform output -raw region)
TS=$(date +%Y%m%d_%H%M%S)
F="Name=tag:Project,Values=EWB-VPC-Peering"
terraform -chdir=terraform output inventory | tee "evidence/inventory_$TS.txt"
{
echo "== VPCs";       aws ec2 describe-vpcs --region $REGION --filters $F --query 'Vpcs[].[Tags[?Key==`Name`]|[0].Value,VpcId,CidrBlock]' --output table
echo "== Subnets";    aws ec2 describe-subnets --region $REGION --filters $F --query 'Subnets[].[Tags[?Key==`Name`]|[0].Value,SubnetId,CidrBlock,MapPublicIpOnLaunch]' --output table
echo "== Route tables + associations + routes"
aws ec2 describe-route-tables --region $REGION --filters $F --output json | python3 -c '
import json,sys
for rt in json.load(sys.stdin)["RouteTables"]:
    name=[t["Value"] for t in rt["Tags"] if t["Key"]=="Name"][0]
    print("\n"+name, rt["RouteTableId"])
    print("  associated subnets:", [a["SubnetId"] for a in rt["Associations"] if "SubnetId" in a])
    for r in rt["Routes"]:
        print("  ", r.get("DestinationCidrBlock"), "->", r.get("GatewayId") or r.get("VpcPeeringConnectionId"), r.get("State"))
'
echo -e "\n== Peering"; aws ec2 describe-vpc-peering-connections --region $REGION --filters $F --query 'VpcPeeringConnections[].[Tags[?Key==`Name`]|[0].Value,VpcPeeringConnectionId,Status.Code,RequesterVpcInfo.VpcId,RequesterVpcInfo.CidrBlock,AccepterVpcInfo.VpcId,AccepterVpcInfo.CidrBlock]' --output table
echo -e "\n== Security group inbound rules"; aws ec2 describe-security-group-rules --region $REGION --filters "Name=group-id,Values=$(terraform -chdir=terraform output -json inventory | python3 -c 'import json,sys;d=json.load(sys.stdin);print(",".join([d["sg_bastion"],d["sg_app_a"],d["sg_app_b"]]))')" --query 'SecurityGroupRules[?IsEgress==`false`].[GroupId,IpProtocol,FromPort,ToPort,CidrIpv4]' --output table
} 2>&1 | tee "evidence/network_$TS.txt"
echo "Saved evidence/inventory_$TS.txt and evidence/network_$TS.txt"
