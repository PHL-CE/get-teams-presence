output "SB_CONN_STRING" {
    value = azurerm_servicebus_queue_authorization_rule.this.primary_connection_string
}

output "QUEUE_NAME" {
    value = azurerm_servicebus_queue.this.name
}

output "CLIENT_ID" {
    value = data.azurerm_client_config.current.client_id
}

output "EMAIL" {
    value = var.email
}