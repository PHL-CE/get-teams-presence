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
  parameters_content = jsonencode({
    "logicAppName" = {
      value = local.arm_params["logicAppName"]
    }
    "When_a_message_is_received_in_a_queue_(auto-complete)Frequency" = {
      value = local.arm_params["Frequency"]
    }
    "When_a_message_is_received_in_a_queue_(auto-complete)Interval" = {
      value = local.arm_params["Interval"]
    }
    "owner_Tag" = {
      value = local.common_tags["Owner"]
    }
    "office365_name" = {
      value = local.arm_params["office365_name"]
    }
    "office365_displayName" = {
      value = local.arm_params["office365_name"]
    }
    "servicebus_name" = {
      value = local.arm_params["servicebus_name"]
    }
    "servicebus_displayName" = {
      value = local.arm_params["servicebus_displayName"]
    }
    "servicebus_namespace_name" = {
      value = local.arm_params["servicebus_namespace_name"]
    }
    "servicebus_resourceGroupName" = {
      value = local.arm_params["servicebus_resourceGroupName"]
    }
    "servicebus_accessKey_name" = {
      value = local.arm_params["servicebus_accessKey_name"]
    }
  })
  template_content = data.template_file.workflow.template
}