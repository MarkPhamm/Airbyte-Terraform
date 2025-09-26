terraform {
  required_version = ">= 1.6.0"
  required_providers {
    airbyte = { source = "airbytehq/airbyte", version = "~> 0.6" }
  }
}

# ---- Provider (points to your local Airbyte) ----
provider "airbyte" {
  server_url    = "http://localhost:8000/api/public/v1/"
  client_id     = var.client_id
  client_secret = var.client_secret
}
# ---- Airbyte Workspace ----
resource "airbyte_workspace" "lab" {
  name = var.workspace_name
}
