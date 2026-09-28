# Libvirt Terraform Infrastructure

Terraform-based local infrastructure for running VMs or Kubernetes cluster on **libvirt/KVM**.

Creates:

- control-plane VMs
- worker VMs
- cloud-init configuration
- SSH access
- generated Ansible inventory
- optional additional worker disks
- optional Kubernetes deployment with Kubespray

Note: to create simple VMs only (without K8s cluster) set CONTROL_PLANE_COUNT to 0


## Requirements

- Linux + libvirt/KVM
- Terraform
- `wget`
- Python 3 + `venv`
- SSH key pair
- Kubespray in `./kubespray/` if Kubernetes deployment is required

Terraform uses:

```
provider "libvirt" {
  uri = "qemu:///system"
}
```

## Quick start

```
make run
```

Example with custom resources:

```
make run \
  CONTROL_PLANE_COUNT=1 \
  CONTROL_PLANE_CPUS=2 \
  CONTROL_PLANE_MEMORY_MB=2048 \
  NODE_COUNT=2 \
  NODE_CPUS=2 \
  NODE_MEMORY_MB=4096
```

This will:

1. initialize Terraform
2. download the VM image if necessary
3. generate `terraform.tfvars`
4. create the VMs
5. generate `inventory.ini`
6. run Kubespray

## Terraform

Infrastructure without Kubernetes:

```
make infra
```

Run Kubespray separately:

```
make cluster
```

## Configuration

### Control plane

```
CONTROL_PLANE_COUNT=1
CONTROL_PLANE_CPUS=2
CONTROL_PLANE_MEMORY_MB=2048
CONTROL_PLANE_DISK_SIZE_GB=20
```

### Workers

```
NODE_COUNT=1
NODE_CPUS=2
NODE_MEMORY_MB=2048
NODE_DISK_SIZE_GB=20
NODE_ADDITIONAL_RAW_DISK_SIZE_GB=20
```

Set `NODE_ADDITIONAL_RAW_DISK_SIZE_GB=0` to disable the additional disk.

### SSH

By default:

```
PRIVATE_SSH_KEY_PATH=$HOME/.ssh/id_ed25519
PUBLIC_SSH_KEY_PATH=$HOME/.ssh/id_ed25519.pub
```

Override if necessary:

```
make run \
  PRIVATE_SSH_KEY_PATH=$HOME/.ssh/my-key \
  PUBLIC_SSH_KEY_PATH=$HOME/.ssh/my-key.pub
```

## VM image

Default image:

```
https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
```

Images are stored in `./images/`.

Use another local image:

```
make run VM_IMAGE=/path/to/image.img
```

## Kubespray

If `./kubespray/` is present, `make cluster` prepares its inventory and runs `cluster.yml`.

The generated inventory is:

```
inventory.ini
```

and is copied into:

```
kubespray/inventory/<INVENTORY_DIR_NAME>/
```

Default inventory name:

```
libvirtd-tf-infra
```
