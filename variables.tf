variable "cpus" {
  type        = number
  description = "Count of CPUs per virtual machine"
}

variable "memory_mb" {
  type        = number
  description = "Count of RAM in MB per virtual machine"
}

variable "vm_count" {
  type        = number
  description = "Count of virtual machines"
}

variable "vm_image" {
  type        = string
  description = "link to image"
}

