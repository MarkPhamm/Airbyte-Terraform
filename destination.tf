# ---- Destination: Snowflake ----
resource "airbyte_destination_snowflake" "snowflake" {
  name         = "sf_internal_stage"
  workspace_id = airbyte_workspace.lab.workspace_id

  configuration = {
    host                  = var.sf_host
    username              = var.sf_user
    password              = var.sf_password
    role                  = var.sf_role
    warehouse             = var.sf_wh
    database              = var.sf_db
    schema                = var.sf_schema
    disable_type_dedupe   = false
    use_merge_for_upsert  = false
    retention_period_days = 1
  }
}
