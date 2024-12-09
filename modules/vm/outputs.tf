output "vm_ids" {
  value = flatten([
    azurerm_virtual_machine.web_vm.id,
    [for db_vm in azurerm_virtual_machine.db_vm : db_vm.id]
  ])
}