variable "public_ssh_key_path" {
  type        = string
  description = "Path to SSH key that will be used for default user on VMs"
}

variable "vm_image" {
  type        = string
  description = "link to image"
}

variable "control_plane_count" {
  type        = number
  description = "Count of virtual machines"
}

variable "node_count" {
  type        = number
  description = "Count of virtual machines"
}

variable "control_plane_cpus" {
  type        = number
  description = "Count of CPUs per control plane"
}

variable "node_cpus" {
  type        = number
  description = "Count of CPUs per node"
}


variable "control_plane_memory_mb" {
  type        = number
  description = "Count of RAM in MB per control plane"
}

variable "node_memory_mb" {
  type        = number
  description = "Count of RAM in MB per node"
}

variable "control_plane_disk_size_gb" {
  type        = number
  description = "Primary disk size for constol plane"
}

variable "node_disk_size_gb" {
  type        = number
  description = "Primary disk size for node severs"
}

variable "node_additional_raw_disk_size_gb" {
  type        = number
  description = "Make additional raw disk on nodes. Set to zero to prevent creating"
}
