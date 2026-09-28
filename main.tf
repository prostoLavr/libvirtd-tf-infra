terraform {
  required_version = ">= 1.3"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
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
  source = var.vm_image
  format = "qcow2"
}

resource "libvirt_volume" "vm_disk" {
  count          = var.vm_count
  name           = "libvirt-tf-infra-vm-disk-${count.index}.qcow2"
  base_volume_id = libvirt_volume.fedora_base.id
  pool           = "default"
  size           = 21474836480 # 20 GB, make flexable 
}

resource "libvirt_volume" "vm_raw_disk" {
  count = var.vm_count
  name  = "libvirt-tf-infra-vm-raw-disk-${count.index}.qcow2"
  pool  = "default"
  size  = 21474836480 # 20 GB, make flexable 
}

resource "libvirt_domain" "libvirt_tf_infra_vm" {
  count  = var.vm_count
  name   = "libvirt-tf-infra-local-vm-${count.index}"
  memory = var.memory_mb
  vcpu   = var.cpus

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.vm_disk[count.index].id
  }

  # TODO: don't attach when ROOK-CEPH is not activated
  disk {
    volume_id = libvirt_volume.vm_raw_disk[count.index].id
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
    for vm in libvirt_domain.libvirt_tf_infra_vm : vm.name => flatten(vm.network_interface[*].addresses)
  }
  description = "Local IP"
}

resource "local_file" "hosts" {
  filename = "./hosts.yaml"
  content = templatefile("${path.module}/hosts.tpl.yml", {
    servers = [
      for vm in libvirt_domain.libvirt_tf_infra_vm : {
        name = vm.name
        ip   = flatten(vm.network_interface[*].addresses)[0]
      }
    ]
  })
}

resource "local_file" "inventory" {
  filename = "./inventory.ini"
  content = templatefile("${path.module}/inventory.tpl.ini", {
    control_planes = [
      for vm in slice(libvirt_domain.libvirt_tf_infra_vm, 0, 1) : {
        name = vm.name
        ip   = flatten(vm.network_interface[*].addresses)[0]
      }
    ],
    nodes = [
      for vm in slice(libvirt_domain.libvirt_tf_infra_vm, 1, length(libvirt_domain.libvirt_tf_infra_vm)) : {
        name = vm.name
        ip   = flatten(vm.network_interface[*].addresses)[0]
      }
    ]
  })
}
