locals {
    name_prefix = "auth-notification"
    location = "eastus2"
    common_tags = {
        Owner = "Pat Lafferty"
        Market = "Philadelphia"
        Manager = "Shanker Mageshwaran"
        Project = "InnovationLab"
    }

    arm_file_path = "../logic_app/Auth-Notification-App.json"
    arm_params = {
        "logicAppName" = azurerm_logic_app_workflow.this.name
        "Frequency" = "Minute"
        "Interval" = 1
        "owner_Tag" = local.common_tags.Owner
        "office365_name" = "Office365"
        "office365_displayName" = var.email
        "servicebus_name" = azurerm_servicebus_queue.this.name
        "servicebus_displayName" = azurerm_servicebus_queue.this.name
        "servicebus_namespace_name" = azurerm_servicebus_namespace.this.name
        "servicebus_queue_name" = azurerm_servicebus_queue.this.name
        "servicebus_resourceGroupName" = azurerm_servicebus_namespace.this.resource_group_name
        "servicebus_accessKey_name" = "RootManageSharedAccessKey"
    }
}