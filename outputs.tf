output "control_planes_ip" {
  value = {
    for vm in libvirt_domain.control_plane_vm : vm.name => flatten(vm.network_interface[*].addresses)
  }
  description = "IP of control planes"
}

output "nodes_ip" {
  value = {
    for vm in libvirt_domain.node_vm : vm.name => flatten(vm.network_interface[*].addresses)
  }
  description = "IP of control planes"
}
