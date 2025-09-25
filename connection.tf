# ---- Connection: Source → Snowflake ----
resource "airbyte_connection" "csv_to_sf" {
  name           = var.connection_name
  source_id      = airbyte_source_file.local_csv.source_id
  destination_id = airbyte_destination_snowflake.snowflake.destination_id

  schedule = {
    schedule_type = "manual"
  }
  namespace_definition = "destination" # writes into var.sf_schema
}
