# ---- Source: HTTP-accessible CSV File using Custom Source ----
# Using airbyte_source_custom for maximum flexibility

resource "airbyte_source_custom" "local_csv" {
  name         = var.dataset_name
  workspace_id = airbyte_workspace.lab.workspace_id

  # File connector definition ID (from your existing setup)
  definition_id = "778daa7c-feaf-4db6-96f3-70fd645acc77"

  configuration = jsonencode({
    dataset_name = var.dataset_name
    format       = "csv"
    url          = "/tmp/vietnam_airlines_review.csv"
    provider = {
      storage = "local"
    }
    reader_options = jsonencode({
      header = 0
    })
  })
}
