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

resource "libvirt_cloudinit_disk" "control_plane_commoninit" {
  count = var.control_plane_count
  name  = "control_plane_commoninit-${count.index}.iso"
  pool  = "default"

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname = "control-plane-${count.index}"
    ssh_key  = file(var.public_ssh_key_path)
  })
}

resource "libvirt_cloudinit_disk" "worker_commoninit" {
  count = var.node_count
  name  = "worker_commoninit-${count.index}.iso"
  pool  = "default"
  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname = "node-${count.index}"
    ssh_key  = file(var.public_ssh_key_path)
  })
}

resource "libvirt_volume" "os_base" {
  name   = "os-base-${basename(var.vm_image)}"
  pool   = "default"
  source = var.vm_image
  format = "qcow2"
}

resource "libvirt_volume" "control_plane_disk" {
  count          = var.control_plane_count
  name           = "control-plane-vm-disk-${count.index}.qcow2"
  base_volume_id = libvirt_volume.os_base.id
  pool           = "default"
  size           = var.control_plane_disk_size_gb * 1024 * 1024 * 1024
}

resource "libvirt_volume" "node_disk" {
  count          = var.node_count
  name           = "node-vm-disk-${count.index}.qcow2"
  base_volume_id = libvirt_volume.os_base.id
  pool           = "default"
  size           = var.node_disk_size_gb * 1024 * 1024 * 1024
}

resource "libvirt_volume" "node_raw_disk" {
  count = var.node_additional_raw_disk_size_gb > 0 ? var.node_count : 0
  name  = "libvirt-tf-infra-vm-raw-disk-${count.index}.qcow2"
  pool  = "default"
  size  = var.node_additional_raw_disk_size_gb * 1024 * 1024 * 1024
}

resource "libvirt_domain" "control_plane_vm" {
  count  = var.control_plane_count
  name   = "control-plane-${count.index}"
  memory = var.control_plane_memory_mb
  vcpu   = var.control_plane_cpus

  cloudinit = libvirt_cloudinit_disk.control_plane_commoninit[count.index].id

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.control_plane_disk[count.index].id
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
resource "libvirt_domain" "node_vm" {
  count  = var.node_count
  name   = "node-${count.index}"
  memory = var.node_memory_mb
  vcpu   = var.node_cpus

  cloudinit = libvirt_cloudinit_disk.worker_commoninit[count.index].id

  cpu {
    mode = "host-passthrough"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.node_disk[count.index].id
  }

  dynamic "disk" {
    for_each = var.node_additional_raw_disk_size_gb > 0 ? [1] : []

    content {
      volume_id = libvirt_volume.node_raw_disk[count.index].id
    }
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


