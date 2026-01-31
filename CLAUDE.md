# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This is a POC comparing Claude Code vs GitHub Copilot CLI for Azure IaC (Bicep) development. The evaluation tests greenfield generation, code understanding, debugging, and end-to-end workflows.

## Key Commands

```bash
# Validate Bicep syntax
az bicep build --file <module>.bicep

# Lint for best practices
az bicep lint --file <module>.bicep

# Preview deployment changes
az deployment group what-if --resource-group <rg> --template-file <file>.bicep

# Convert bicepparam to JSON for deployment
az bicep build-params --file <file>.bicepparam --outfile <file>.parameters.json

# Deploy to resource group
az deployment group create --resource-group <rg> --template-file <file>.bicep --parameters @<file>.parameters.json
```

## Architecture

- **infra/cc/**: Claude Code generated Bicep deployments
- **infra/cp/**: GitHub Copilot CLI generated Bicep deployments
- **scenarios/**: Test prompts organized by phase (phase1-greenfield, phase2-existing-code, phase3-debugging, phase4-workflow)
- **results/scorecard.md**: Evaluation results using weighted scoring from EVALUATION.md
- **.github/workflows/**: Deployment pipelines for each task

## Azure Environment

| Setting | Value |
|---------|-------|
| Claude Code resource group | `rg-eastus2-claude` |
| Copilot CLI resource group | `rg-eastus2-copilot` |
| Region | East US 2 |
| Environment | DEV only |

GitHub secrets for authentication: `CLIENT_ID`, `SECRET_ID`, `SUBSCRIPTION_ID`, `TENANT_ID`

## Naming Conventions

**Format:** `{resourceType}-{workload}-{tool}-{environment}-{region}`

- Use `cc` prefix for Claude Code resources (e.g., `vnet-hub-cc-dev-eus2`)
- Use `cp` prefix for Copilot CLI resources
- Storage accounts: 24 char max, no hyphens (e.g., `stpocccdeveus2001`)
- Key Vaults: 24 char max, include uniqueString for global uniqueness

## Bicep Standards (from AGENTS.md)

- Always declare `targetScope`
- All parameters require `@description()` decorators
- Use `@allowed()` for finite valid values
- API versions must be 2023-01-01 or newer
- Never hardcode subscription/tenant IDs
- Enable diagnostic settings on all resources that support them (note: route tables don't support diagnostics)
- Private endpoints required for PaaS services
- TLS 1.2 minimum, HTTPS only for storage
- RBAC authorization for Key Vault (not access policies)
- Tag all resources: `environment`, `owner`, `costCenter`, `project`

## Known Azure Runtime Behaviors

These cause deployment failures despite valid Bicep syntax:

- **Key Vault names are globally unique** - use `uniqueString(resourceGroup().id)` suffix
- **RBAC propagation takes time** - create managed identities in prerequisites, not same deployment as consumer
- **Blob versioning incompatible with HNS** - don't enable versioning on Data Lake Gen2 storage
- **Route tables don't support diagnostic settings**
- **VNet subnet operations conflict during gateway provisioning** - add explicit `dependsOn` for subnets created after Firewall/Bastion/Gateway

## Evaluation Criteria

Weighted scoring (max 5.0):
- Accuracy: 25% (deploys successfully, follows best practices)
- Completeness: 20% (all requirements + diagnostics, tags)
- Speed: 15% (time to working code)
- Iteration Efficiency: 15% (number of fix iterations)
- Context Understanding: 15% (follows existing patterns)
- Explanation Quality: 10% (explains architecture decisions)
