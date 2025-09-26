# Airbyte-Terraform

Tiny, laptop-only lab that loads a **local CSV → Snowflake (free trial)** using **Airbyte OSS + Terraform**. Minimal creds, minimal moving parts.

---

# What you’ll do

1. Spin up Airbyte locally (with `abctl`) and grab API creds.
2. Drop your CSV under Airbyte’s local mount.
3. Create a Snowflake trial and run one SQL snippet to make a role/user/DB/WH/schema.
4. Use Terraform to declare:

   * **Source:** File (local CSV)
   * **Destination:** Snowflake (Internal Staging)
   * **Connection:** manual schedule
5. Sync once; query the table in Snowflake.

---

## 0) Start Airbyte locally + get API creds

```bash
curl -LsfS https://get.airbyte.com | bash -
abctl local install
abctl local credentials
# → prints email, password, client-id, client-secret
```

`abctl` is the supported local path; `abctl local credentials` prints the login + OAuth client for the Terraform provider. ([Airbyte Docs][1])

---

## 1) Put your CSV where Airbyte can see it

Airbyte’s **local filesystem** source requires URLs starting with `/local/`, which map to a host folder (by default `/tmp/airbyte_local`). Create a folder and copy your file there: ([Airbyte Docs][2])

```bash
mkdir -p /tmp/airbyte_local/csvs
cp ~/Downloads/orders.csv /tmp/airbyte_local/csvs/
# the source URL you’ll use is: /local/csvs/orders.csv
```

Note: on macOS/Windows ensure Docker has access to `/tmp` (Windows may need `LOCAL_ROOT` env tweaks; see docs). ([Airbyte Docs][2])

---

## 2) Create a Snowflake trial + objects

Sign up for a free trial, then in Snowsight open a worksheet and run this (edit names/password if you like). This is the exact pattern Airbyte recommends: ware­house, DB, schema, role, user. ([Airbyte Docs][3])

```sql
-- Run as ACCOUNTADMIN
set airbyte_role      = 'AIRBYTE_ROLE';
set airbyte_username  = 'AIRBYTE_USER';
set airbyte_warehouse = 'AIRBYTE_WAREHOUSE';
set airbyte_database  = 'AIRBYTE_DATABASE';
set airbyte_schema    = 'AIRBYTE_SCHEMA';
set airbyte_password  = 'ChangeMe123!';

begin;
use role securityadmin;
create role if not exists identifier($airbyte_role);
grant role identifier($airbyte_role) to role SYSADMIN;

create user if not exists identifier($airbyte_username)
  password = $airbyte_password
  default_role = $airbyte_role
  default_warehouse = $airbyte_warehouse;
grant role identifier($airbyte_role) to user identifier($airbyte_username);

use role sysadmin;
create warehouse if not exists identifier($airbyte_warehouse)
  warehouse_size = xsmall auto_suspend = 60 auto_resume = true initially_suspended = true;
create database if not exists identifier($airbyte_database);

grant usage on warehouse identifier($airbyte_warehouse) to role identifier($airbyte_role);
grant ownership on database identifier($airbyte_database) to role identifier($airbyte_role);

use database identifier($airbyte_database);
create schema if not exists identifier($airbyte_schema);
grant ownership on schema identifier($airbyte_schema) to role identifier($airbyte_role);
commit;
```

You’ll need the **host** like `account.region.cloud.snowflakecomputing.com`, plus the role/warehouse/database/schema/user you just created. Airbyte’s Snowflake destination uses **Internal Staging** for loading (fast + simple). ([Airbyte Docs][3])

---

## 3) Terraform config (single `main.tf`)

Paste this into `tf-csv-to-sf/main.tf`:

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    airbyte = { source = "airbytehq/airbyte", version = "~> 0.6" }
  }
}

# ---- Provider (points to your local Airbyte) ----
variable "client_id"     { type = string }
variable "client_secret" { type = string }
provider "airbyte" {
  server_url    = "http://localhost:8000/api/public/v1/"
  client_id     = var.client_id
  client_secret = var.client_secret
}

# ---- Optional: keep this lab isolated in its own workspace ----
resource "airbyte_workspace" "lab" { name = "tf-csv-to-snowflake" }

# ---- Source: local File (CSV) ----
# Use JSON-style "custom" to keep schema simple and stable.
resource "airbyte_source_custom" "local_csv" {
  name         = "orders_csv"
  workspace_id = airbyte_workspace.lab.workspace_id

  configuration = jsonencode({
    source_type   = "file",
    dataset_name  = "orders_csv",         # becomes your table name
    format        = "csv",
    provider      = { storage = "local" },# local filesystem
    url           = "/local/csvs/orders.csv",
    # Optional: pandas read_csv options as a JSON string (header row etc.)
    reader_options = "{\"header\": 0}"
  })
}

# ---- Destination: Snowflake (typed resource) ----
variable "sf_host"      { type = string } # e.g. account.us-east-2.aws.snowflakecomputing.com
variable "sf_user"      { type = string }
variable "sf_password"  { type = string }
variable "sf_role"      { type = string }
variable "sf_wh"        { type = string }
variable "sf_db"        { type = string }
variable "sf_schema"    { type = string }

resource "airbyte_destination_snowflake" "snowflake" {
  name         = "sf_internal_stage"
  workspace_id = airbyte_workspace.lab.workspace_id

  configuration = {
    destination_type = "snowflake"
    host             = var.sf_host
    username         = var.sf_user
    password         = var.sf_password
    role             = var.sf_role
    warehouse        = var.sf_wh
    database         = var.sf_db
    schema           = var.sf_schema

    # Recommended: Internal Staging (no S3/GCS required)
    loading_method = {
      destination_snowflake_data_staging_method_recommended_internal_staging = {
        method = "Internal Staging"
      }
    }
  }
}

# ---- Connection: Source → Snowflake (manual schedule) ----
resource "airbyte_connection" "csv_to_sf" {
  name           = "csv_to_snowflake"
  source_id      = airbyte_source_custom.local_csv.source_id
  destination_id = airbyte_destination_snowflake.snowflake.destination_id

  schedule_type        = "manual"
  namespace_definition = "destination"   # writes into var.sf_schema
}
```

Why this shape?

* **Local file source** requires `/local/...` URL and maps to `/tmp/airbyte_local` on your host. We use the JSON “custom” resource so you don’t chase typed schema changes. ([Airbyte Docs][2])
* **Snowflake dest (typed)** makes Internal Staging explicit and accepted by the provider schema. ([Terraform Registry][4])
* Snowflake host format and required fields (role/warehouse/db/schema/user/pass) match the destination docs. ([Airbyte Docs][3])

---

## 4) Apply and run one sync

```bash
cd tf-csv-to-sf

# Airbyte API creds from `abctl local credentials`
export TF_VAR_client_id="YOUR_CLIENT_ID"
export TF_VAR_client_secret="YOUR_CLIENT_SECRET"

# Snowflake details from Step 2
export TF_VAR_sf_host="YOUR_ACCT.region.cloud.snowflakecomputing.com"
export TF_VAR_sf_user="AIRBYTE_USER"
export TF_VAR_sf_password="ChangeMe123!"
export TF_VAR_sf_role="AIRBYTE_ROLE"
export TF_VAR_sf_wh="AIRBYTE_WAREHOUSE"
export TF_VAR_sf_db="AIRBYTE_DATABASE"
export TF_VAR_sf_schema="AIRBYTE_SCHEMA"

terraform init
terraform apply -auto-approve
```

Open Airbyte at `http://localhost:8000` → **Connections → csv_to_snowflake → Sync now** (we set it to manual). Airbyte’s Snowflake destination uses **Internal Stage** under the hood. ([Airbyte Docs][5])

---

## 5) Verify in Snowflake

In a worksheet with role `AIRBYTE_ROLE`:

```sql
use warehouse AIRBYTE_WAREHOUSE;
select count(*) from AIRBYTE_DATABASE.AIRBYTE_SCHEMA.orders_csv;
select * from AIRBYTE_DATABASE.AIRBYTE_SCHEMA.orders_csv limit 20;
```

By default Airbyte also writes raw JSON to an internal schema; your final table is the one named by the file **dataset_name** (`orders_csv`). ([Airbyte Docs][3])

---

## Common gotchas (quick)

* **File not found:** ensure the file is under `/tmp/airbyte_local/...` on your host and your source URL starts with `/local/...`. On Windows, you may need to set `LOCAL_ROOT` / `LOCAL_DOCKER_MOUNT`. ([Airbyte Docs][2])
* **Snowflake connect errors:** double-check **host** domain format and that the **warehouse** exists/starts; the destination requires role/warehouse/db/schema you created. ([Airbyte Docs][3])

[1]: https://docs.airbyte.com/platform/next/deploying-airbyte/abctl?utm_source=chatgpt.com "abctl | Airbyte Docs"
[2]: https://docs.airbyte.com/integrations/sources/file "File (CSV, JSON, Excel, Feather, Parquet) Connector | Airbyte Documentation"
[3]: https://docs.airbyte.com/integrations/destinations/snowflake "Snowflake Connector | Airbyte Documentation"
[4]: https://registry.terraform.io/providers/airbytehq/airbyte/0.6.3/docs/resources/destination_snowflake?utm_source=chatgpt.com "airbyte_destination_snowflake | Resources | airbytehq/airbyte ..."
[5]: https://docs.airbyte.com/platform/deploying-airbyte/integrations/authentication?utm_source=chatgpt.com "Authentication - Airbyte Docs"

```
python3 -m http.server 8080
```
