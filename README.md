# This is the repository for Terraform deployment of the network security laboratory environment

**Main branch: lab1 configurations**  
**lab2 branch: lab2 configurations**  


# Installation instructions

This installation instruction is designed for Ubuntu operating system, but similar approach with your specific OS's package handler will work.

## Install and setup libvirtd and necessary packages for UEFI virtualization
```
sudo apt update
sudo apt-get install qemu-kvm libvirt-daemon-system virt-top libguestfs-tools ovmf
sudo adduser $USER libvirt
sudo usermod -aG libvirt $(whoami)
```

Start and enable libvirtd
```
sudo systemctl start libvirtd
sudo systemctl enable libvirtd
```

## Install terraform
Follow specific instructions for your system

https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

### verify terraform is accessible and the CLI works
```
which terraform
terraform --version
```


### install virt-manager for VM accessibility
```
sudo apt-get install virt-install virt-viewer
sudo apt-get install virt-manager
```

### install qemu and verify the installation
https://www.qemu.org/download/#linux
```
qemu-system-x86_64 --version
```
### download the relevant images & place them in the directory containing main.tf

TO-DO: Insert image download links here!

### Install mkisofs
```
sudo apt-get install -y mkisofs
```

### Install xsltproc 
```
sudo apt-get install xsltproc
```

### Initialize default volume storage pool
Defining this pool to point to ./volumes makes it easier for us to control the resources, also it avoids having to deal with any permission issues. Also keeping all of the resources under "master" directory lets us easily delete all the resources once we are done with the laboratories.

```
sudo virsh pool-define /dev/stdin <<EOF
<pool type='dir'>
  <name>default_pool</name>
  <target>
    <path>$PWD/volumes</path>
  </target>
</pool>
EOF

sudo virsh pool-start default_pool
sudo virsh pool-autostart default_pool
```

### Configure user permisions for libvirt to storage pool
```
sudo chown -R $(whoami):libvirt ./images
sudo systemctl restart libvirtd
```


### Provision the platform with Terraform
```
export TERRAFORM_LIBVIRT_TEST_DOMAIN_TYPE="qemu"
terraform init
terraform apply
```

# Troubleshooting:
```
General problems with first deployment:
solution:
run the cleanup.sh script

NOTE: After first successful deployment, do not use the cleanup.sh anymore, instead use terraform destroy!!

```


```
problem:
Error: Error defining libvirt domain: virError(Code=67, Domain=10, Message='unsupported configuration: Emulator '/usr/bin/qemu-system-x86_64' does not support virt type 'kvm'')

solution 1:
try export TERRAFORM_LIBVIRT_TEST_DOMAIN_TYPE="qemu"

solution2:
enable virtualization in the host system
```

```
problem:
pool default not found

solution:
sudo virsh pool-define /dev/stdin <<EOF
<pool type='dir'>
  <name>default</name>
  <target>
    <path>$PWD/images</path>
  </target>
</pool>
EOF

sudo virsh pool-start default
sudo virsh pool-autostart default
```

```
problem: VM is stuck at "booting from hard disk..."
solution: Verify that you have installed the OVMF package to allow for UEFI virtualization
```

