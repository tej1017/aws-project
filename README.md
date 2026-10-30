# AWS VPC Peering — EWB Student Project 01

Terraform + helper scripts that build the workbook's exact network (names, CIDRs, IPs, routes, security groups),
run the tests, and save real evidence to `evidence/`.

## Prerequisites
Terraform >= 1.5, AWS CLI configured for your lab account, OpenSSH (WSL on Windows), python3.

## Steps
```bash
# 0. Key pair: generated locally, only the PUBLIC key goes to AWS
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ewb-lab.pem -N ""
chmod 400 ~/.ssh/ewb-lab.pem

# 1. Configure
cd terraform
cp terraform.tfvars.example terraform.tfvars    # edit name + your /32
# curl -s https://checkip.amazonaws.com

# 2. PHASE 1 - build everything WITHOUT peering (baseline)
terraform init && terraform apply
cd .. && scripts/gen-ssh-config.sh
scripts/verify.sh baseline          # Test 01: ping must FAIL

# 3. PHASE 2 - peering + routes
terraform -chdir=terraform apply -var enable_peering=true
scripts/verify.sh peered            # Tests 02-05 must pass

# 4. Controlled failure
scripts/controlled-failure.sh

# 5. Capture inventory/routes/SG evidence, then take console screenshots (Checkpoints 01-04)
scripts/collect-evidence.sh

# 6. Cleanup (after saving evidence)
terraform -chdir=terraform destroy
scripts/cleanup-check.sh
aws ec2 delete-key-pair --key-name ewb-lab   # only if Terraform did not remove it
rm ~/.ssh/ewb-lab.pem ~/.ssh/ewb-lab.pem.pub
```
Re-run `scripts/gen-ssh-config.sh` if the bastion public IP changes. If your own IP changes, update `my_ip_cidr` and apply.
If the controlled-failure script ran, Terraform state still matches (rule restored), but `terraform apply` will fix any drift.

## Notes
- Peering uses `auto_accept = true` (same account/Region), equivalent to Request + Accept.
- No NAT gateway; VPC B has no internet gateway; app hosts have no public IP.
- Keys are never committed (`.gitignore`). Do not put private keys in the report.
- Submit a PDF named `YourName_EWB_VPC_Peering.pdf` built from `REPORT_TEMPLATE.md` plus your screenshots.

## Repo layout
```
terraform/   infrastructure (phase 1 baseline, phase 2 peering via enable_peering)
scripts/     gen-ssh-config, verify, controlled-failure, collect-evidence, cleanup-check
docs/        architecture diagram, routing + security reference, test plan, submission checklist
evidence/    YOUR real outputs go here (commit them)
REPORT_TEMPLATE.md   report outline -> export to YourName_EWB_VPC_Peering.pdf
```
Sample output format (illustrative only, not real): `examples/sample-evidence/`.

See `docs/architecture.md` for the diagram and `docs/submission-checklist.md` before submitting.
