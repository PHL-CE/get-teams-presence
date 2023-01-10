data "template_file" "workflow" {
  template = file(local.arm_file_path)
}

data "azurerm_client_config" "current" {}

data "azuread_application" "this" {
  display_name = var.ad_app_name
}