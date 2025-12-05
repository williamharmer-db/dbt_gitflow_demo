# Magnum D&A Platform: ETL Deployment Operating Model

## 1. Summary

### The What
This document frames the dbt deployment operating model for ETL within the Magnum D&A platform. Where we will utilize **dbt** to model data, **Databricks** to execute the compute and store the data (Delta Lake), and **Azure DevOps** to manage repositories, pipelines, and releases.

### The Why
The team is starting with a blank canvas, presenting a unique opportunity to embed an effective, modern deployment operating model from the beginning. Our primary aim is to enable the data engineering teams to maintain a **high release velocity**—releasing changes to production several times a day, without compromising data quality or stability.

---

## 2. Foundational Principles

To achieve high velocity, we are shifting from "running ETL scripts" to "building data products". Our workflow is grounded in five Engineering principles:

1.  **Idempotency:** "Running it twice shouldn't break it"
    * Models are built as `CREATE OR REPLACE`. If a job fails, we simply retry it. There should be no manual cleanup required.
2.  **Atomicity:** "The user sees either the old valid state or the new valid state but never a broken middle state"
    * We build data in a staging area first. The "release" is a metadata swap. Downstream users are never exposed to half-built tables.
3.  **State Awareness (Slim CI):** "Don't rebuild the whole car just to change the tire"
    * Our CI pipelines compare the new code against the current production manifest. We only test what has changed, keeping feedback loops fast (minutes, not hours).
4.  **Ephemeral Environments:** "Treat test environments as ephemeral, not persistent"
    * CI environments are spun up on-demand for a Pull Request and destroyed immediately after. This prevents environment drift.
5.  **Immutability:** "Append or Rebuild."
    * We avoid expensive `UPDATE` statements on historical data where possible, preferring full rebuilds or append-only logic to ensure consistency.

---

## 3. Operational Scenarios & Solutions

We have designed this operating model to specifically address the bottlenecks common in scaling data teams.

| Scenario | Challenge | Operating Model Solution |
| :--- | :--- | :--- |
| **Concurrent Development** | Two engineers (Alice and Bob) work on related models simultaneously. Merging one breaks the other's logic. | **Feature Branching & Isolated Schemas:** Engineers work in personal schemas (`dbt_alice`). Code is only merged via Pull Request after peer review. |
| **Integration Risks** | A change to a core table passes local tests but breaks a downstream report managed by another team. | **Automated CI Pipelines:** Every PR triggers a dbt build in Azure DevOps. We test the modified model *and* all downstream dependencies before merging. |
| **Release Bottlenecks** | A full production run takes 1 hour. We cannot deploy 5 times a day if we have to wait 1 hour for every deployment. | **State-Based Selection:** Our pipelines use `dbt build --select state:modified+`. We only build and test the specific subset of the DAG that changed. |
| **Compute Efficiency** | Testing on full production data volumes is expensive and slow. | **Zero-Copy Cloning:** We utilize `dbt clone` (Databricks Shallow Clone) to instantly create test environments with production data references, without duplicating the physical storage. |

---

## 4. The Git Workflow: Trunk-Based Development

We adhere to **Trunk-Based Development**. There is one source of truth (`main`), and it is always in a deployable state.

### Branching Strategy
* **`main`**: The production codebase. Protected. No direct pushes allowed.
* **`feat/*`**: Short-lived feature branches created by developers (e.g., `feat/add-churn-metric`).

### The Lifecycle of a Change

#### Step 1: Branch & Code (Local)
The engineer creates a new branch from `main`. They develop locally, running models against their private development schema in Databricks.
```bash
git checkout -b feat/new-logic
dbt run --select my_model
```

#### Step 2: Open Pull Request (Azure DevOps)
The engineer pushes the branch to Azure DevOps and opens a **Pull Request (PR)**.
* **Requirement:** A concise description of the change.
* **Trigger:** This automatically triggers the **CI Pipeline**.

#### Step 3: Continuous Integration (The Quality Gate)
The CI Pipeline runs in Azure DevOps. It performs the following checks using `dbt`:
1. **Linting:** Checks SQL style.
2. **Slim CI Build:**
   ```bash
   dbt build --select state:modified+ --defer --state path/to/prod/manifest
   ```

This runs models and tests ONLY for the changed code and its downstream dependencies.

#### Step 4: Peer Review & Merge
Once the CI pipeline passes (green checkmark), a peer reviews the code. Upon approval, the branch is Squash Merged into main.

#### Step 5: Production Deployment (CD)
The merge to main triggers the Production Pipeline:
* **Deploy**: Runs dbt build against the production schema in Databricks.
* **Docs**: Generates and publishes updated dbt documentation.
* **Artifacts**: Saves the manifest.json to be used as the comparison baseline for the next CI run.

## 5. Environment Architecture
To support this workflow, we maintain distinct environments within Databricks.

| Environment | Purpose | Write Access | Data Location | 
| :--- | :--- | :--- | :--- |
| Development | Sandbox for active coding. | Developers | db_dev_user_schema |
| Integration (CI) | Temporary testing for PRs. | Azure DevOps (Service Principal) | db_ci_pr_<id> (Ephemeral) |
| Production | The source of truth for BI/Reporting. | Azure DevOps (Service Principal) | db_analytics_prod |