output "boot_diagnostics_account_name" {
    description = "Name of created storage account"
    value = "${azurerm_storage_account.vm-sa.name}"
}

output "boot_diagnostics_account_endpoint" {
    description = "Blob endpoint for boot diagnostics storage account"
    value = "${azurerm_storage_account.vm-sa.primary_blob_endpoint}"
}