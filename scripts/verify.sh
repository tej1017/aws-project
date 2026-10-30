#!/usr/bin/env bash
# Usage: scripts/verify.sh baseline | peered
# Runs the workbook tests and saves REAL output to evidence/ (page 11).
set -uo pipefail
cd "$(dirname "$0")/.."
SSH="ssh -F ssh_config.generated"
PHASE=${1:?usage: verify.sh baseline|peered}
OUT="evidence/${PHASE}_$(date +%Y%m%d_%H%M%S).txt"
run() { echo -e "\n### $*"; "$@" 2>&1; echo "[exit code: $?]"; }
{
echo "Phase: $PHASE   Date: $(date -u +%FT%TZ)"
case "$PHASE" in
  baseline)
    echo "== Bastion SSH (should work: laptop -> bastion)"
    run $SSH ewb-bastion "hostname; hostname -I"
    echo "== App-A SSH via bastion (should work: VPC A local route)"
    run $SSH ewb-app-a "hostname; hostname -I"
    echo "== Test 01 Baseline: App-A -> App-B (EXPECTED: no replies / 100% loss)"
    run $SSH ewb-app-a "ping -c 4 -W 2 10.20.1.10"
    ;;
  peered)
    echo "== Test 02 Forward: App-A -> App-B (EXPECTED: 4 received, 0% loss)"
    run $SSH ewb-app-a "hostname; hostname -I; ping -c 4 10.20.1.10"
    echo "== Test 03 Reverse: App-B -> App-A (EXPECTED: 4 received, 0% loss)"
    run $SSH ewb-app-b "hostname; hostname -I; ping -c 4 10.10.2.10"
    echo "== Test 04 Private SSH to App-B through bastion"
    run $SSH ewb-app-b "echo connected-to-\$(hostname)"
    echo "== Test 05 Isolation: public IPv4 per instance (EXPECTED: None for app-a / app-b)"
    for n in ewb-bastion ewb-app-a ewb-app-b; do
      run aws ec2 describe-instances --filters "Name=tag:Name,Values=$n" "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceId,PrivateIpAddress,PublicIpAddress]' --output text
    done
    ;;
  *) echo "unknown phase"; exit 1;;
esac
} | tee "$OUT"
echo -e "\nSaved: $OUT   (also screenshot the terminal; label host/test/result)"
