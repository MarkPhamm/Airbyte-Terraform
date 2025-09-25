# ---- Source: Local CSV File ----
# Dynamically constructs the file path using current working directory
locals {
  csv_file_path = "${path.cwd}/${var.data_directory}/${var.csv_filename}"
}

resource "airbyte_source_file" "local_csv" {
  name         = var.dataset_name
  workspace_id = airbyte_workspace.lab.workspace_id

  configuration = {
    dataset_name = var.dataset_name
    format       = "csv"
    url          = "file://${local.csv_file_path}"
    provider = {
      local_filesystem_limited = {}
    }
    reader_options = jsonencode({
      header = 0
    })
  }
}
