#!/usr/bin/make

ifneq ("$(wildcard .env)","")
    include .env
    export $(shell sed 's/=.*//' .env)
endif

IMAGE_LINK := https://download.fedoraproject.org/pub/fedora/linux/releases/44/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-44-1.7.x86_64.qcow2
IMAGE_PATH := $(CURDIR)/images/
VM_IMAGE := $(IMAGE_PATH)$(notdir $(IMAGE_LINK))
CPUS := 2
MEMORY_MB := 2048
VM_COUNT := 1

.ONESHELL:
RUN_ARGS := $(wordlist 2,100,$(MAKECMDGOALS))
$(eval $(RUN_ARGS):;@:)

.PHONY: help

help: ## Help
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'


build_tfvars:
	@rm -f terraform.tfvars
	@cat << EOF > terraform.tfvars
	cpus = $$(echo "$${LIBVIRTD_TF_INFRA_CPUS:-$(CPUS)}")
	memory_mb = $$(echo "$${LIBVIRTD_TF_INFRA_MEMORY_MB:-$(MEMORY_MB)}")
	vm_count = $$(echo "$${LIBVIRTD_TF_INFRA_VM_COUNT:-$(VM_COUNT)}")
	vm_image = "$$(echo "$${LIBVIRTD_TF_INFRA_IMAGE:-file://$(VM_IMAGE)}")"
	EOF


init:
	# @systemctl start libvirtd
	@terraform init
	echo "$(VM_IMAGE)"
	@if [ -z "$$LIBVIRTD_TF_INFRA_IMAGE" ]; then \
		if [ ! -d $(IMAGE_PATH) ]; then \
			mkdir -p $(IMAGE_PATH); \
		fi
		if [[ ! -f "$(VM_IMAGE)" ]]; then \
			wget $(IMAGE_LINK) $(IMAGE_PATH); \
		fi
	fi

apply: 
	terraform apply

destroy:
	@terraform destroy

run: init build_tfvars apply ## Run virtual machines

stop: destroy ## Stop virtual machines
