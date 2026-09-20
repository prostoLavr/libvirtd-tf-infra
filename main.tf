terraform {
  required_version = ">= 1.3"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}


resource "libvirt_cloudinit_disk" "commoninit" {
  count = var.vm_count
  name  = "commoninit-${count.index}.iso"
  pool  = "default"

  user_data = <<EOF
#cloud-config
hostname: node-${count.index}
users:
  - name: ansible
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, wheel
    home: /home/ansible
    shell: /bin/bash
    ssh_authorized_keys:
      - ${file("~/.ssh/id_ed25519.pub")}
ssh_pwauth: false
disable_root: true
EOF
}

resource "libvirt_volume" "fedora_base" {
  name   = "fedora_base.qcow2"
  pool   = "default"
  source = "file:///home/lawrence/Downloads/Fedora-Cloud-Base-Generic-44-1.7.x86_64.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "vm_disk" {
  count          = var.vm_count
  name           = "fedora-vm-disk-${count.index}.qcow2"
  base_volume_id = libvirt_volume.fedora_base.id
  pool           = "default"
  size           = 21474836480 # 20 GB
}

resource "libvirt_domain" "fedora_vm" {
  count  = var.vm_count
  name   = "fedora-local-vm-${count.index}"
  memory = var.memory_mb
  vcpu   = var.cpus

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.vm_disk[count.index].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

output "vm_ip" {
  value = {
    for vm in libvirt_domain.fedora_vm : vm.name => flatten(vm.network_interface[*].addresses)
  }
  description = "Local IP"
}

