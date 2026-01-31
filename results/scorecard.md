# POC Evaluation Scorecard

**Evaluator:** Thomas Johnson
**Date Range:** 2026-01-31
**Azure Subscription:** d4d87481-29f1-4fd5-8f95-1bd9465ad7c9

---

## Phase 1: Greenfield Generation

### Task 1.1: Storage Account Module

| Criterion | Claude Code | Copilot CLI |
|-----------|-------------|-------------|
| Accuracy (25%) | 3/5 | 1/5 |
| Completeness (20%) | 5/5 | 1/5 |
| Speed (15%) | 2/5 | 1/5 |
| Iteration Efficiency (15%) | 2/5 | /5 |
| Context Understanding (15%) | 4/5 | /5 |
| Explanation Quality (10%) | 4/5 | /5 |
| **Weighted Total** | **3.25** | |

**Time:** Claude ~30 min | Copilot ___ min
**Iterations:** Claude 3 | Copilot ___

**Claude Code Notes:**
1. Initial code generated quickly with all features (CMK, private endpoint, TLS 1.2, soft delete, diagnostics)
2. Fix 1: Key Vault name not globally unique - added uniqueString suffix
3. Fix 2: RBAC propagation timing - moved managed identity to prerequisites
4. Fix 3: Blob versioning incompatible with HNS-enabled storage
5. Strong completeness: included all security controls without being asked

**Copilot CLI Notes:**
1. After 13 iterations, still didn't complete phase 1 deployments.
2. Multiple error categories, workflow syntax errors, bicep parameter errors, azure authentication errors.

Summary of actions (Phase 1):

Generated Bicep templates and sample parameters for all Phase 1 tasks under infra/cp.
Ran local validation for all Phase 1 templates; fixed syntax issues for storage account and management group policy logic.
Added a Phase 1 deployment workflow and composite validation action, then iteratively fixed pipeline errors (format check, auth, CLI flags, bicepparam conversion).
Performance assessment:

Accuracy: Moderate. Templates validate locally, but required several fixes and pipeline iterations.
Completeness: High for Phase 1 deliverables, including workflow/action.
Speed/Iteration Efficiency: Low–moderate due to multiple pipeline corrections.
Context Understanding: Mixed; initially created infra/cc in error, later corrected focus to infra/cp.




**Winner:** [x] Claude Code  [ ] Copilot CLI  [ ] Tie

---

### Task 1.2: Hub Virtual Network

| Criterion | Claude Code | Copilot CLI |
|-----------|-------------|-------------|
| Accuracy (25%) | 3/5 | /5 |
| Completeness (20%) | 5/5 | /5 |
| Speed (15%) | 3/5 | /5 |
| Iteration Efficiency (15%) | 3/5 | /5 |
| Context Understanding (15%) | 4/5 | /5 |
| Explanation Quality (10%) | 4/5 | /5 |
| **Weighted Total** | **3.55** | |

**Time:** Claude ~25 min | Copilot ___ min
**Iterations:** Claude 2 | Copilot ___

**Claude Code Notes:**
1. Generated complete hub VNet with all components: Azure Firewall (Standard, zone-redundant), Bastion (Standard), VPN Gateway (Gen2, BGP), Route Tables, NSG
2. Fix 1: Route tables don't support diagnostic settings - removed
3. Fix 2: SharedServicesSubnet dependency conflict with VPN Gateway provisioning - added explicit dependsOn
4. Proactively added zone redundancy for Firewall and Gateway public IPs
5. Comprehensive diagnostic settings for all supported resources
6. Identified redundancy with prerequisites VNet (2 VNets deployed) - user chose to keep as designed

**Copilot CLI Notes:**
-

**Winner:** [x] Claude Code  [ ] Copilot CLI  [ ] Tie

---

### Task 1.3: Subscription-Scoped Policies

| Criterion | Claude Code | Copilot CLI |
|-----------|-------------|-------------|
| Accuracy (25%) | 4/5 | /5 |
| Completeness (20%) | 5/5 | /5 |
| Speed (15%) | 4/5 | /5 |
| Iteration Efficiency (15%) | 4/5 | /5 |
| Context Understanding (15%) | 4/5 | /5 |
| Explanation Quality (10%) | 4/5 | /5 |
| **Weighted Total** | **4.15** | |

**Time:** Claude ~10 min | Copilot ___ min
**Iterations:** Claude 1 | Copilot ___

**Claude Code Notes:**
1. Adapted ALZ management group scope to subscription scope per plan constraints
2. Created modular structure: policyDefinitions.bicep, policyAssignments.bicep, roleAssignments.bicep, main.bicep
3. Fix 1: Parameter naming conflict with `description` decorator - renamed to `assignmentDescription`
4. All custom policies: TLS 1.2 (Deny), Private Endpoints (Audit), Allowed VM SKUs (Deny)
5. Built-in policy: Allowed Locations
6. Conditional RBAC assignments (only deploy if group IDs provided)
7. No deployment failures - issue caught during local validation

**Copilot CLI Notes:**
-

**Winner:** [x] Claude Code  [ ] Copilot CLI  [ ] Tie

---

## Phase 1 Summary - Claude Code

### Commit History
| Commit | Description |
|--------|-------------|
| `ea9b59e` | Initial Phase 1 code (~1375 lines Bicep + 5 workflows) |
| `44683f9` | Fix: Randomize Key Vault name |
| `462092e` | Fix: Move managed identity to prerequisites |
| `b89bea3` | Fix: Remove versioning for HNS storage |
| `c5c7713` | Fix: Remove route table diagnostics |
| `75ad7b8` | Fix: Add subnet dependencies |

### Positive Patterns Observed
- [x] Proactively added security controls not requested (zone redundancy, soft delete)
- [x] Generated reusable, modular code (policy modules)
- [x] Included helpful comments
- [x] Ran validation commands automatically (`az bicep build`)
- [x] Correctly handled Azure naming conventions
- [x] Created comprehensive GitHub Actions with verification steps

### Negative Patterns Observed
- [x] Didn't anticipate HNS + versioning incompatibility
- [x] Didn't know route tables don't support diagnostics
- [x] RBAC propagation timing not anticipated
- [x] Key Vault global uniqueness not considered initially
- [x] VNet subnet/gateway dependency timing missed

### Key Insight
Most failures were **Azure-specific runtime behaviors** rather than code quality issues. The Bicep was syntactically valid with current API versions, but Azure's actual deployment behavior revealed edge cases not documented in schema.

---

## Phase 2: Existing Code Understanding

### Task 2.1: Explain Peering

| Criterion | Claude Code | Copilot CLI |
|-----------|-------------|-------------|
| Accuracy (25%) | /5 | /5 |
| Completeness (20%) | /5 | /5 |
| Speed (15%) | /5 | /5 |
| Iteration Efficiency (15%) | /5 | /5 |
| Context Understanding (15%) | /5 | /5 |
| Explanation Quality (10%) | /5 | /5 |
| **Weighted Total** | | |

**Claude Code Notes:**
-

**Copilot CLI Notes:**
-

**Winner:** [ ] Claude Code  [ ] Copilot CLI  [ ] Tie

---

### Task 2.2: Add New Spoke

| Criterion | Claude Code | Copilot CLI |
|-----------|-------------|-------------|
| Accuracy (25%) | /5 | /5 |
| Completeness (20%) | /5 | /5 |
| Speed (15%) | /5 | /5 |
| Iteration Efficiency (15%) | /5 | /5 |
| Context Understanding (15%) | /5 | /5 |
| Explanation Quality (10%) | /5 | /5 |
| **Weighted Total** | | |

**Time:** Claude ___ min | Copilot ___ min
**Iterations:** Claude ___ | Copilot ___

**Claude Code Notes:**
-

**Copilot CLI Notes:**
-

**Winner:** [ ] Claude Code  [ ] Copilot CLI  [ ] Tie

---

### Task 2.3: Refactor Modules

| Criterion | Claude Code | Copilot CLI |
|-----------|-------------|-------------|
| Accuracy (25%) | /5 | /5 |
| Completeness (20%) | /5 | /5 |
| Speed (15%) | /5 | /5 |
| Iteration Efficiency (15%) | /5 | /5 |
| Context Understanding (15%) | /5 | /5 |
| Explanation Quality (10%) | /5 | /5 |
| **Weighted Total** | | |

**Time:** Claude ___ min | Copilot ___ min
**Iterations:** Claude ___ | Copilot ___

**Claude Code Notes:**
-

**Copilot CLI Notes:**
-

**Winner:** [ ] Claude Code  [ ] Copilot CLI  [ ] Tie

---

## Phase 3: Debugging

### Task 3.1: RBAC Failure

| Criterion | Claude Code | Copilot CLI |
|-----------|-------------|-------------|
| Accuracy (25%) | /5 | /5 |
| Completeness (20%) | /5 | /5 |
| Speed (15%) | /5 | /5 |
| Iteration Efficiency (15%) | /5 | /5 |
| Context Understanding (15%) | /5 | /5 |
| Explanation Quality (10%) | /5 | /5 |
| **Weighted Total** | | |

**Claude Code Notes:**
-

**Copilot CLI Notes:**
-

**Winner:** [ ] Claude Code  [ ] Copilot CLI  [ ] Tie

---

### Task 3.2: DNS Resolution

| Criterion | Claude Code | Copilot CLI |
|-----------|-------------|-------------|
| Accuracy (25%) | /5 | /5 |
| Completeness (20%) | /5 | /5 |
| Speed (15%) | /5 | /5 |
| Iteration Efficiency (15%) | /5 | /5 |
| Context Understanding (15%) | /5 | /5 |
| Explanation Quality (10%) | /5 | /5 |
| **Weighted Total** | | |

**Claude Code Notes:**
-

**Copilot CLI Notes:**
-

**Winner:** [ ] Claude Code  [ ] Copilot CLI  [ ] Tie

---

### Task 3.3: Circular Dependency

| Criterion | Claude Code | Copilot CLI |
|-----------|-------------|-------------|
| Accuracy (25%) | /5 | /5 |
| Completeness (20%) | /5 | /5 |
| Speed (15%) | /5 | /5 |
| Iteration Efficiency (15%) | /5 | /5 |
| Context Understanding (15%) | /5 | /5 |
| Explanation Quality (10%) | /5 | /5 |
| **Weighted Total** | | |

**Time:** Claude ___ min | Copilot ___ min
**Iterations:** Claude ___ | Copilot ___

**Claude Code Notes:**
-

**Copilot CLI Notes:**
-

**Winner:** [ ] Claude Code  [ ] Copilot CLI  [ ] Tie

---

## Phase 4: End-to-End Workflow

### Task 4.1: Deploy and Validate

| Criterion | Claude Code | Copilot CLI |
|-----------|-------------|-------------|
| Accuracy (25%) | /5 | /5 |
| Completeness (20%) | /5 | /5 |
| Speed (15%) | /5 | /5 |
| Iteration Efficiency (15%) | /5 | /5 |
| Context Understanding (15%) | /5 | /5 |
| Explanation Quality (10%) | /5 | /5 |
| **Weighted Total** | | |

**Time:** Claude ___ min | Copilot ___ min
**Iterations:** Claude ___ | Copilot ___

**Agentic Behavior Notes:**
- Did Claude Code run commands autonomously? [ ] Yes [ ] No
- Did Copilot CLI run commands autonomously? [ ] Yes [ ] No
- Self-correction on errors? Claude: [ ] Yes [ ] No | Copilot: [ ] Yes [ ] No

**Winner:** [ ] Claude Code  [ ] Copilot CLI  [ ] Tie

---

### Task 4.2: CI/CD Pipeline

| Criterion | Claude Code | Copilot CLI |
|-----------|-------------|-------------|
| Accuracy (25%) | /5 | /5 |
| Completeness (20%) | /5 | /5 |
| Speed (15%) | /5 | /5 |
| Iteration Efficiency (15%) | /5 | /5 |
| Context Understanding (15%) | /5 | /5 |
| Explanation Quality (10%) | /5 | /5 |
| **Weighted Total** | | |

**Time:** Claude ___ min | Copilot ___ min
**Iterations:** Claude ___ | Copilot ___

**Claude Code Notes:**
-

**Copilot CLI Notes:**
-

**Winner:** [ ] Claude Code  [ ] Copilot CLI  [ ] Tie

---

## Summary

### Scores by Phase

| Phase | Claude Code Avg | Copilot CLI Avg | Winner |
|-------|-----------------|-----------------|--------|
| Phase 1: Greenfield | 3.65 | N/A | Claude Code |
| Phase 2: Existing Code | | | |
| Phase 3: Debugging | | | |
| Phase 4: Workflow | | | |
| **Overall** | | | |

### Scores by Criterion (All Tasks)

| Criterion | Claude Code Avg | Copilot CLI Avg |
|-----------|-----------------|-----------------|
| Accuracy | 3.33 | |
| Completeness | 5.00 | |
| Speed | 3.00 | |
| Iteration Efficiency | 3.00 | |
| Context Understanding | 4.00 | |
| Explanation Quality | 4.00 | |

### Key Observations

**Claude Code Strengths:**
1. Excellent completeness - included security controls, diagnostics, and modular design without being asked
2. Good error interpretation and self-correction when given deployment errors
3. Created working GitHub Actions workflows with validation and verification steps

**Claude Code Weaknesses:**
1. Gaps in Azure operational knowledge (HNS+versioning, route table diagnostics, RBAC timing)
2. Multiple iterations needed for runtime issues not caught during validation
3. Did not anticipate global uniqueness requirements for Key Vault names

**Copilot CLI Strengths:**
1.
2.
3.

**Copilot CLI Weaknesses:**
1. After 13 iterations, still didn't complete Phase 1 deployments
2. Multiple error categories: workflow syntax, bicep parameters, Azure authentication
3. Initially created files in wrong directory (infra/cc instead of infra/cp)

### Recommendation

_Based on this evaluation, the recommended tool for Azure Landing Zone IaC development is:_

[ ] **Claude Code** - Best for: _______________

[ ] **Copilot CLI** - Best for: _______________

[ ] **Both** - Use Claude Code for ___________, Copilot CLI for ___________

### Additional Notes

**Phase 1 Code Generated by Claude Code:**
- 1,375 lines of Bicep across 11 files
- 5 GitHub Actions workflows
- 6 total commits (1 initial + 5 fixes)
