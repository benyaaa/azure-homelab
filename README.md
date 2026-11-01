# Azure Data & ML Home Lab

A low-cost, fully scripted Azure lab for practising data and ML engineering:
ADLS Gen2, Azure Data Factory, Key Vault, Azure Databricks (optional) and CI/CD.

**Design rule:** everything except the guardrails is disposable. Run `lab-up` at the
start of a session and `lab-down` at the end. You pay for hours you actually use.

```
azure-homelab/
├── bootstrap/                 # Run ONCE. Persistent, near-zero cost.
│   └── main.tf                #   budget alerts, policy guardrails, Terraform state storage
├── lab/                       # Run every session. Destroy when done.
│   ├── main.tf                #   resource group, ADLS Gen2 (landing/bronze/silver/gold)
│   ├── keyvault.tf            #   Key Vault (RBAC mode)
│   ├── adf.tf                 #   Data Factory + managed identity + linked services
│   ├── databricks.tf          #   Databricks workspace + Unity Catalog access connector (toggle)
│   └── ...
├── databricks/
│   └── cluster-policy.json    # Cluster policy: auto-terminate, small nodes, spot
├── scripts/
│   ├── lab-up.sh / lab-down.sh
│   └── leftovers.sh           # "Is anything still running?" check
└── .github/workflows/terraform-ci.yml   # fmt + validate on every push (no cloud creds needed)
```

## Prerequisites

- Azure subscription (pay-as-you-go, free trial, or Visual Studio credit — the last one has a hard cap)
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) and `az login`
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.9
- Written against the `azurerm` provider 5.x (5.1 at the time of writing)

## 1. Bootstrap (once)

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # fill in subscription_id, alert_email
terraform init
terraform apply
```

This creates:
- a **monthly budget** (default €25) emailing you at 50% / 80% / 100% actual and 100% forecast
- **policy guardrails** at subscription level: allowed regions and an allow-list of small VM sizes
  (Databricks clusters are VMs, so this also stops you accidentally launching a big cluster)
- a small storage account holding Terraform remote state

Note the outputs; they go into `lab/backend.hcl`.

> Budgets alert, they do not stop spending. The policy guardrails and `lab-down` are what
> actually keep costs down.

## 2. Each session

```bash
cp lab/backend.hcl.example lab/backend.hcl          # once: fill in values from bootstrap outputs
cp lab/terraform.tfvars.example lab/terraform.tfvars  # once

./scripts/lab-up.sh          # ~5-10 min with Databricks, ~2 min without
# ... work ...
./scripts/lab-down.sh        # destroys the whole lab resource group
./scripts/leftovers.sh       # confirm nothing is left running
```

Set `enable_databricks = false` in `terraform.tfvars` for ADF/ADLS-only sessions.

## Rough cost (check the Azure pricing calculator for your region)

| Item | When idle | When used |
|---|---|---|
| ADLS Gen2 (a few GB) | cents/month | cents |
| Data Factory | €0 | about €1 per 1,000 activity runs; avoid Data Flows |
| Key Vault | €0 | cents |
| Databricks workspace | ~€0 (small managed storage) | single-node small cluster ≈ €0.5–1/hour (VM + DBUs) |
| Budget, policies | free | free |

## Cost traps this repo avoids on purpose

- **NAT gateway:** Databricks' default "no public IP" mode creates a NAT gateway (~€30+/month,
  even when idle). `no_public_ip = false` avoids it. In a real company you'd use VNet injection
  and private networking; at home it's not worth the standing cost.
- **No Log Analytics workspace**, no diagnostic settings (ingestion charges add up quietly).
- **Key Vault purge on destroy**, so names don't collide and nothing lingers soft-deleted.
- **No Data Flows, no self-hosted IR, no SQL warehouses** in the default lab.

## Secrets hygiene

- `terraform.tfvars`, `backend.hcl` and state files are git-ignored.
- Enable GitHub secret scanning and push protection on your repo.
- Never put keys in notebooks: use Key Vault + Databricks secret scopes or managed identities.
