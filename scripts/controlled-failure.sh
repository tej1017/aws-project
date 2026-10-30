#!/usr/bin/env bash
# Controlled failure (page 11): remove ONLY App-B's ICMP echo rule from 10.10.2.10/32,
# ping fails, restore the exact rule, ping works again. SSH rule untouched.
set -uo pipefail
cd "$(dirname "$0")/.."
SSH="ssh -F ssh_config.generated"
REGION=$(terraform -chdir=terraform output -raw region)
SG=$(terraform -chdir=terraform output -json inventory | python3 -c 'import json,sys;print(json.load(sys.stdin)["sg_app_b"])')
OUT="evidence/controlled_failure_$(date +%Y%m%d_%H%M%S).txt"
{
echo "SG: $SG  Region: $REGION"
RULE=$(aws ec2 describe-security-group-rules --region "$REGION" --filters Name=group-id,Values="$SG" \
  --query 'SecurityGroupRules[?IsEgress==`false` && IpProtocol==`icmp` && CidrIpv4==`10.10.2.10/32`].SecurityGroupRuleId|[0]' --output text)
echo "ICMP rule id: $RULE"
[ "$RULE" = "None" ] && { echo "rule not found"; exit 1; }
echo -e "\n### BEFORE (expect success)"; $SSH ewb-app-a "ping -c 4 -W 2 10.20.1.10"
echo -e "\n### REMOVING ICMP rule"; aws ec2 revoke-security-group-ingress --region "$REGION" --group-id "$SG" --security-group-rule-ids "$RULE"
sleep 5
echo -e "\n### DURING (expect 100% loss)"; $SSH ewb-app-a "ping -c 4 -W 2 10.20.1.10"
echo -e "\n### RESTORING exact rule (ICMP type 8 code 0 from 10.10.2.10/32)"
aws ec2 authorize-security-group-ingress --region "$REGION" --group-id "$SG" \
  --ip-permissions 'IpProtocol=icmp,FromPort=8,ToPort=0,IpRanges=[{CidrIp=10.10.2.10/32,Description=Echo request from App-A}]'
sleep 5
echo -e "\n### AFTER (expect success)"; $SSH ewb-app-a "ping -c 4 -W 2 10.20.1.10"
} 2>&1 | tee "$OUT"
echo "Saved: $OUT"
