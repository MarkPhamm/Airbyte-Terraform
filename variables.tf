# ---- Airbyte Provider Variables ----
variable "client_id" {
  description = "Airbyte API client ID"
  type        = string
}

variable "client_secret" {
  description = "Airbyte API client secret"
  type        = string
  sensitive   = true
}

# ---- Data Source Variables ----
variable "data_directory" {
  description = "Directory containing the data files"
  type        = string
  default     = "data"
}

variable "csv_filename" {
  description = "Name of the CSV file to process"
  type        = string
  default     = "vietnam_airlines_review.csv"
}

variable "dataset_name" {
  description = "Name for the dataset (becomes table name)"
  type        = string
  default     = "vietnam_airlines_reviews"
}

# ---- Snowflake Configuration Variables ----
variable "sf_host" {
  description = "Snowflake account URL (e.g. account.us-east-2.aws.snowflakecomputing.com)"
  type        = string
}

variable "sf_user" {
  description = "Snowflake username"
  type        = string
}

variable "sf_password" {
  description = "Snowflake password"
  type        = string
  sensitive   = true
}

variable "sf_role" {
  description = "Snowflake role"
  type        = string
}

variable "sf_wh" {
  description = "Snowflake warehouse name"
  type        = string
}

variable "sf_db" {
  description = "Snowflake database name"
  type        = string
}

variable "sf_schema" {
  description = "Snowflake schema name"
  type        = string
}

# ---- Workspace Configuration ----
variable "workspace_name" {
  description = "Name for the Airbyte workspace"
  type        = string
  default     = "tf-csv-to-snowflake"
}

variable "connection_name" {
  description = "Name for the Airbyte connection"
  type        = string
  default     = "csv_to_snowflake"
}
