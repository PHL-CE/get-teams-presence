output "SB_CONN_STRING" {
    value = azurerm_servicebus_queue_authorization_rule.this.primary_connection_string
    sensitive = true
}

output "QUEUE_NAME" {
    value = azurerm_servicebus_queue.this.name
}

output "CLIENT_ID" {
    value = data.azuread_application.this.application_id
}

output "EMAIL" {
    value = var.email
}