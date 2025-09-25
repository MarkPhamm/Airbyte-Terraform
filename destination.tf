# ---- Destination: Snowflake ----
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
