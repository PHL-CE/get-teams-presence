resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}-rg"
  location = local.location
  tags     = local.common_tags
}

resource "azurerm_servicebus_namespace" "this" {
  name                = "${local.name_prefix}-bus"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_servicebus_queue" "this" {
  name         = "${local.name_prefix}-queue"
  namespace_id = azurerm_servicebus_namespace.this.id
  enable_partitioning = true
}

resource "azurerm_servicebus_queue_authorization_rule" "this" {
  name     = "${local.name_prefix}-queue-rule"
  queue_id = azurerm_servicebus_queue.this.id

  listen = true
  send   = true
  manage = true
}

// Create an instance of logic app and configure the tags
resource "azurerm_logic_app_workflow" "this" {
  name                = "${local.name_prefix}-la"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.common_tags
}

// Deploy the ARM template workflow
resource "azurerm_resource_group_template_deployment" "this" {
  depends_on = [azurerm_logic_app_workflow.this]
  name = "${local.name_prefix}-deployment"
  resource_group_name = azurerm_resource_group.this.name
  deployment_mode = "Incremental"
  parameters_content = merge({
    "workflowName" = azurerm_logic_app_workflow.this.name
    "location"     = azurerm_resource_group.this.location
  }, local.arm_params)
  template_content = data.template_file.workflow.template
}