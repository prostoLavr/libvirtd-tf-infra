# LibVirtD TF Infra

## Run
```shell
make run CPUS=2 MEMORY_MB=2048 VM_COUNT=3 
```
or configure using env vars

```shell
LIBVIRTD_TF_INFRA_CPUS=2 LIBVIRTD_TF_INFRA_MEMORY_MB=2048 LIBVIRTD_TF_INFRA_VM_COUNT=3 make run
```
This command pre-configures environment, creates terraform.tfvars file and makes terraform apply
