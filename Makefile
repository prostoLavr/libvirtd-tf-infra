#!/usr/bin/make

IMAGE_LINK ?= https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
IMAGES_PATH ?= $(CURDIR)/images/
VM_IMAGE ?= $(IMAGES_PATH)$(notdir $(IMAGE_LINK))
PRIVATE_SSH_KEY_PATH ?= $(HOME)/.ssh/id_ed25519
PUBLIC_SSH_KEY_PATH ?= $(PRIVATE_SSH_KEY_PATH).pub

CONTROL_PLANE_COUNT ?= 1
CONTROL_PLANE_CPUS ?= 2
CONTROL_PLANE_MEMORY_MB ?= 2048
CONTROL_PLANE_DISK_SIZE_GB ?= 20

NODE_COUNT ?= 1
NODE_CPUS ?= 2
NODE_MEMORY_MB ?= 2048
NODE_DISK_SIZE_GB ?= 20
NODE_ADDITIONAL_RAW_DISK_SIZE_GB ?= 20

INVENTORY_DIR_NAME ?= libvirtd-tf-infra
.DEFAULT_GOAL := run

.ONESHELL:

build-tfvars:
	@rm -f terraform.tfvars
	@cat << EOF > terraform.tfvars
	vm_image = "$(VM_IMAGE)"
	public_ssh_key_path = "$(PUBLIC_SSH_KEY_PATH)"
	control_plane_count = $(CONTROL_PLANE_COUNT)
	control_plane_cpus = $(CONTROL_PLANE_CPUS)
	control_plane_memory_mb = $(CONTROL_PLANE_MEMORY_MB)
	control_plane_disk_size_gb = $(CONTROL_PLANE_DISK_SIZE_GB)
	node_count = $(NODE_COUNT)
	node_cpus = $(NODE_CPUS)
	node_memory_mb = $(NODE_MEMORY_MB)
	node_disk_size_gb = $(NODE_DISK_SIZE_GB)
	node_additional_raw_disk_size_gb = $(NODE_ADDITIONAL_RAW_DISK_SIZE_GB)
	EOF


init:
	terraform init

download-image:
	@mkdir -p "$(IMAGES_PATH)"
	@if [ ! -f "$(VM_IMAGE)" ]; then
		wget -O "$(VM_IMAGE)" "$(IMAGE_LINK)";
	fi

apply: 
	terraform apply

destroy:
	terraform destroy

kubespray-check-inventory-dir:
	@if [[ ! -d ./kubespray/inventory/$(INVENTORY_DIR_NAME) ]]; then
		cp -r ./kubespray/inventory/sample/ ./kubespray/inventory/$(INVENTORY_DIR_NAME)/
	fi

kubespray-copy-inventory-ini:
	cp ./inventory.ini ./kubespray/inventory/$(INVENTORY_DIR_NAME)/

kubespray-venv:
	@cd ./kubespray && \
	if [[ ! -d ./venv ]]; then
		python3 -m venv venv
		./venv/bin/pip install -r requirements.txt
	fi && \
	cd ..

kubespray-if-needed:
	@if [[ "$(CONTROL_PLANE_COUNT)" -gt 0 ]]; then
		$(MAKE) kubespray-venv
		$(MAKE) kubespray-check-inventory-dir
		$(MAKE) kubespray-copy-inventory-ini
		cd kubespray && \
		./venv/bin/ansible-playbook \
			-i inventory/$(INVENTORY_DIR_NAME)/inventory.ini \
			-b -v \
			-u ansible \
			--private-key=$(PRIVATE_SSH_KEY_PATH) \
			cluster.yml
	fi

infra: init download-image build-tfvars apply
cluster: kubespray-if-needed
run: infra cluster

stop: destroy ## Stop virtual machines
