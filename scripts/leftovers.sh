#!/usr/bin/env bash
# "Am I paying for something I forgot?" — lists anything outside the core RG.
set -euo pipefail

echo "== Resource groups (only rg-homelab-core should be listed) =="
az group list --query "[].{name:name, location:location}" -o table

echo
echo "== Running VMs anywhere in the subscription (should be empty) =="
az vm list -d --query "[?powerState=='VM running'].{name:name, rg:resourceGroup, size:hardwareProfile.vmSize}" -o table

echo
echo "== Resources not in rg-homelab-core (Azure-managed RGs like NetworkWatcherRG are fine) =="
az resource list --query "[?resourceGroup!='rg-homelab-core'].{type:type, name:name, rg:resourceGroup}" -o table
