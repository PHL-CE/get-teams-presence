data "template_file" "workflow" {
  template = file(local.arm_file_path)
}

data "azurerm_client_config" "current" {}
