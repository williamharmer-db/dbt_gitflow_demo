# TMICC Analytics - dbt Project

This project is designed to demonstrate a high-velocity Data Engineering operating model using dbt and Databricks. It adheres to the principles of Idempotency, Atomicity, State Awareness, Ephemeral Environments, and Immutability.

## Engineering Principles Implemented

1.  **Idempotency**: 
    - `dim_users` is a `table` (Create or Replace).
    - `fct_events` is `incremental` with a `unique_key` merge strategy, ensuring re-runs don't duplicate data.
2.  **Atomicity**: 
    - Data is built in staging views (`models/staging`) before being materialized in marts.
    - Deployment uses `dbt build` which runs models and tests together.
3.  **State Awareness (Slim CI)**:
    - CI pipelines should run `dbt build --select state:modified+` to test only changes.
4.  **Ephemeral Environments**:
    - `macros/generate_schema_name.sql` dynamically routes CI runs to `db_ci_pr_<id>` schemas, ensuring isolation.
5.  **Immutability**:
    - `fct_events` favors append-logic (incremental) over updates.

## Environment Architecture

The `macros/generate_schema_name.sql` file orchestrates where data lands based on the environment:

| Environment | Target Name | Schema Pattern |
| :--- | :--- | :--- |
| **Development** | `dev` | `dbt_<user>_<custom_schema>` (e.g., `dbt_alice_marts`) |
| **CI** | `ci` | `db_ci_pr_<PR_ID>_<custom_schema>` |
| **Production** | `prod` | `db_analytics_prod_<custom_schema>` |

## Getting Started

### 1. Configure Credentials
Copy `profiles.yml.template` to `~/.dbt/profiles.yml` and fill in your Databricks credentials.

### 2. Development Workflow (Trunk-Based)

1.  **Branch**: `git checkout -b feat/my-feature`
2.  **Develop**: 
    ```bash
    dbt build --select my_model
    ```
    This writes to your personal schema (e.g., `dbt_alice`).
3.  **PR**: Push to `feat/my-feature` and open a Pull Request.
    - CI triggers automatically.
    - Runs: `dbt build --select state:modified+ --defer --state path/to/prod_artifacts`
    - This builds ONLY changed models in a temporary `db_ci_pr_123` schema.
4.  **Merge**: Upon approval, merge to `main`.
    - CD deploys to `db_analytics_prod`.

## Project Structure

- `models/staging`: Views on raw data (Renaming, casting).
- `models/marts`: Business logic tables (Dimensions, Facts).
- `macros`: Custom logic for schema management (`generate_schema_name.sql`).
- `tests`: Data integrity tests (Unique, Not Null, Relationships).

## Key Configurations

- **Profiles**: See `profiles.yml.template` for `dev`, `ci`, and `prod` targets.
- **Packages**: Uses `dbt_utils` and `dbt_expectations`.

