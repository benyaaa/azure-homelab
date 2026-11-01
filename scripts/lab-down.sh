#!/usr/bin/env bash
# Destroy the whole lab. Bootstrap (budget, policies, state) is untouched.
set -euo pipefail
cd "$(dirname "$0")/../lab"

terraform init -backend-config=backend.hcl -input=false >/dev/null
terraform destroy -input=false "$@"

# Belt and braces: if anything was clicked in outside Terraform, remove the RG too.
if az group exists --name rg-homelab-lab | grep -q true; then
  echo "rg-homelab-lab still exists, deleting it..."
  az group delete --name rg-homelab-lab --yes --no-wait
fi

echo "Lab destroyed. Run ./scripts/leftovers.sh in a few minutes to confirm."
