#!/usr/bin/env bash
# Create (or update) the disposable lab.
set -euo pipefail
cd "$(dirname "$0")/../lab"

az account show --query "{subscription:name, user:user.name}" -o table

terraform init -backend-config=backend.hcl -input=false >/dev/null
terraform apply -input=false "$@"

echo
echo "Lab is up. Remember: ./scripts/lab-down.sh when you're done."
terraform output
