variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = true
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = "rg-blob-upload-trigger-uksouth"
}

variable "location" {
  description = "The location/region to keep all your network resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = "uksouth"
}

variable "storage_account_name" {
  description = "The name of the azure storage account"
  default     = ""
}

variable "account_kind" {
  description = "The type of storage account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2."
  default     = "StorageV2"
}

variable "skuname" {
  description = "The SKUs supported by Microsoft Azure Storage. Valid options are Premium_LRS, Premium_ZRS, Standard_GRS, Standard_GZRS, Standard_LRS, Standard_RAGRS, Standard_RAGZRS, Standard_ZRS"
  default     = "Standard_RAGRS"
}

variable "access_tier" {
  description = "Defines the access tier for BlobStorage and StorageV2 accounts. Valid options are Hot and Cool."
  default     = "Hot"
}

variable "min_tls_version" {
  description = "The minimum supported TLS version for the storage account"
  default     = "TLS1_2"
}

variable "assign_identity" {
  description = "Set to `true` to enable system-assigned managed identity, or `false` to disable it."
  default     = true
}

variable "soft_delete_retention" {
  description = "Number of retention days for soft delete. If set to null it will disable soft delete all together."
  default     = 30
}

variable "enable_advanced_threat_protection" {
  description = "Boolean flag which controls if advanced threat protection is enabled."
  default     = false
}

variable "network_rules" {
  description = "Network rules restricing access to the storage account."
  type        = object({ bypass = list(string), ip_rules = list(string), subnet_ids = list(string) })
  default     = null
}

variable "containers_list" {
  description = "List of containers to create and their access levels."
  type        = list(object({ name = string, access_type = string }))
  default     = [{"name" = "rawimages", "access_type" = "private"}, {"name" = "processedimages", "access_type" = "private"}]
}

variable "lifecycles" {
  description = "Configure Azure Storage firewalls and virtual networks"
  type        = list(object({ prefix_match = set(string), tier_to_cool_after_days = number, tier_to_archive_after_days = number, delete_after_days = number, snapshot_delete_after_days = number }))
  default     = []
}

variable "app_service_plan_name" {
  description = "The name of the App Service plan to create."
  default     = "asp-blob-upload-trigger"
}

variable "tier" {
  description = "The tier the function app will use. (defaults to Consumption)"
  default     = "Dynamic"
}

variable "size" {
  description = "The size the function app will use. (defaults to Consumption)"
  default     = "Y1"
}

variable "function_app_name" {
  description = "Specifies the name of the Function App. Changing this forces a new resource to be created."
  default = "fa-blob-upload-trigger"
}

variable "runtime_version" {
  description = "The runtime version of the Function App."
  default     = "~3"
}

variable "app_settings" {
  description = "Function App settings."
  default     = {}
}

variable "cors_allowed_origins" {
  description = "Allowed origins (CORS) for the Function App."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
