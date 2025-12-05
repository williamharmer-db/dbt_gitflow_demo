# Local Development Setup Guide

This guide will help you get your local environment set up to contribute to the project.

## 1. Install Prerequisites

Ensure you have the following installed:
- **Python 3.9+**
- **Git**
- **VS Code** (Recommended)

## 2. Install dbt

We use `dbt-databricks`. Run the following in your terminal:

```bash
pip install dbt-databricks sqlfluff
```

## 3. Configure Credentials

### Step 1: Get Your Databricks Credentials

Log into your Databricks workspace and gather the following:

1.  **Workspace Host**: Your Databricks URL (without `https://`)
    *   Example: `adb-1234567890123456.7.azuredatabricks.net`

2.  **SQL Warehouse HTTP Path**: 
    *   Go to **SQL Warehouses** → Select your warehouse → **Connection details**
    *   Example: `/sql/1.0/warehouses/abc123def456`

3.  **Personal Access Token**:
    *   Go to **Settings** (top right) → **User Settings** → **Developer** → **Access Tokens**
    *   Click **Generate new token** → Copy it immediately (you won't see it again!)

### Step 2: Set Up Environment Variables

I've already created `~/.dbt/profiles.yml` for you. It reads credentials from environment variables for security.

1.  Copy the template:
    ```bash
    cp env.template .env
    ```

2.  Edit `.env` with your actual credentials:
    ```bash
    nano .env  # or use VS Code
    ```

3.  Load the environment variables:
    ```bash
    source .env
    ```

**Important**: Run `source .env` every time you open a new terminal, or add it to your `~/.zshrc` to load automatically.

## 4. Initialize Project Dependencies

Install the dbt packages defined in `packages.yml` (dbt_utils, dbt_expectations):

```bash
dbt deps
```

## 5. Verify Setup

Run a debug check to ensure you can connect:

```bash
dbt debug
```

If all checks pass, you are ready to code!

## 6. Common Commands

*   **Build everything:** `dbt build`
*   **Build specific model:** `dbt build --select my_model`
*   **Run Tests:** `dbt test`
*   **Lint Code:** `sqlfluff lint models/`

