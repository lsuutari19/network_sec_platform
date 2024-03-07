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
sudo chown -R $(whoami):libvirt $PWD/volumes
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
pool default_pool not found

solution:
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

```
problem:
Error: error creating libvirt domain: Cannot access storage file '/network_sec_platform/volumes/kali-qcow2' (as uid:962, gid:962): Permission denied

solution:
make sure that your user belongs to the libvirt group and the libvirt group has permissions to this directory, also make sure that "sudo virsh pool-dumpxml default_pool" gives the something like the following:

<pool type='dir'>
  <name>default_pool</name>
  <uuid>3aeb4e71-811c-40f6-bc78-0dbf8f7f2b8c</uuid>
  <capacity unit='bytes'>1005388820480</capacity>
  <allocation unit='bytes'>623110905856</allocation>
  <available unit='bytes'>382277914624</available>
  <source>
  </source>
  <target>
    <path>home/user/network_sec_laboratory/volumes</path>
    <permissions>
      <mode>0755</mode>
      <owner>58320</owner>
      <group>100</group>
    </permissions>
  </target>
</pool>

```

```
problem: VM is stuck at "booting from hard disk..."
solution: Verify that you have installed the OVMF package to allow for UEFI virtualization
```

