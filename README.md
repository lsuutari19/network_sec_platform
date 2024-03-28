# This is the repository for Terraform deployment of the network security laboratory environment

**Main branch: lab1 configurations**  
**lab2 branch: lab2 configurations**  


# Installation instructions

This installation instruction is designed for Ubuntu operating system, but similar approach with your specific OS's package handler will work.

## Install and setup libvirtd and necessary packages for UEFI virtualization
```
sudo apt update
sudo apt-get install qemu-kvm libvirt-daemon-system virt-top libguestfs-tools ovmf bridge-utils dnsmasq ebtables
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
### Download the relevant images & place them in the directory containing main.tf

Following table summarizes the required images with download links for this lab:

Image name|Image size|Download Link
:-:|:-:|:-:
Kali linux | 14.6 gb | [kali download](https://a3s.fi/swift/v1/AUTH_d797295bcbc24cec98686c41a8e16ef5/CloudAndNetworkSecurity/kali-linux-2023.4-qemu-amd64.zip)
Ubuntu server | 1.8 gb | [server download](https://a3s.fi/swift/v1/AUTH_d797295bcbc24cec98686c41a8e16ef5/CloudAndNetworkSecurity/ubuntu_server.qcow2)
pfSense | 1 gb | [pfsense download](https://a3s.fi/swift/v1/AUTH_d797295bcbc24cec98686c41a8e16ef5/CloudAndNetworkSecurity/router_pfsense.qcow2)

The repository for terraform deployment can be cloned using the link below

```shell
git clone https://github.com/lsuutari19/network_sec_platform
```
There are three images that you need to download (links provided above) and place them into directory _network_sec_platform/images_ 

They have following names:

1) kali-linux-2023.4-qemu-amd64.qcow2
2) router_pfsense.qcow2
3) ubuntu_server.qcow2

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

### Configure user permisions for qemu + libvirt to storage pool
```
sudo chown -R $(whoami):libvirt $PWD/volumes
```
Edit /etc/libvirt/qemu.conf file & uncomment user, group and security_driver, and make the following changes:
```
# Some examples of valid values are:
#
#       user = "qemu"   # A user named "qemu"
#       user = "+0"     # Super user (uid=0)
#       user = "100"    # A user named "100" or a user with uid=100
#
user = "<username>"
# The group for QEMU processes run by the system instance. It can be
# specified in a similar way to user.
group = "libvirt"
...
security_driver = "none"
```
```
sudo systemctl restart libvirtd
```


### Provision the platform with Terraform
```
export TERRAFORM_LIBVIRT_TEST_DOMAIN_TYPE="qemu"
terraform init
terraform apply
```
**Notes:**
- The ubuntu-domain takes a minute to start due to the nature of the cloud images and their preconfigurations.
- On a lot of OS's SELinux/apparmor messes up with the permissions for libvirt, uncomment and change /etc/libvirt/qemu.conf user and group: https://ostechnix.com/solved-cannot-access-storage-file-permission-denied-error-in-kvm-libvirt/
- To make sure networks autostart after a shutdown of hostmachine you can run
```
  virsh net-autostart internal_network && virsh net-autostart external_network && virsh net-autostart demilitarized_zone
```

# Troubleshooting:
```
General problems with first deployment:
solution:
run the cleanup.sh script
If some resources fail to get removed by terraform check the virsh commands in the cleanup.sh (more at https://download.libvirt.org/virshcmdref/html-single/)

NOTE: After first successful deployment, do not use the cleanup.sh anymore, instead use terraform destroy!!

```

```
problem: restarting VMs not working after a shutdown, because xxx network is not up
solution:

virsh net-start internal_network
virsh net-start external_network
virsh net-start demilitarized_zone

```

```
problem:  Mouse is not working very well in the Kali VM
solution: add a tablet input option in virt-manager to the machine by clicking the blue info button under the "File" option and choose "Add Hardware" -> "Input" -> "Type: EvTouch USB Graphics Tablet" -> "Finish"
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
Error: error creating libvirt domain: Cannot access storage file '/network_sec_platform/volumes/kali-volume.qcow2' (as uid:962, gid:962): Permission denied

solution 1: 
uncomment and change /etc/libvirt/qemu.conf user and group: https://ostechnix.com/solved-cannot-access-storage-file-permission-denied-error-in-kvm-libvirt/ https://github.com/dmacvicar/terraform-provider-libvirt/issues/546

solution 2:
change the security driver in /etc/libvirt/qemu.conf to "none": https://github.com/dmacvicar/terraform-provider-libvirt/issues/546

solution 3:
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
    <path>home/user/network_sec_platform/volumes</path>
    <permissions>
      <mode>0755</mode>
      <owner>58320</owner>
      <group>100</group>
    </permissions>
  </target>
</pool>

```

```
problem: 
Error: error defining libvirt domain: unsupported configuration: spice graphics are not supported with this QEMU

solution:
Try installing "qemu-full" package
```

```
problem: VM is stuck at "booting from hard disk..."
solution: Verify that you have installed the OVMF package to allow for UEFI virtualization
```
```
problem: Cant create a shared filesystem virtiofsd "Unable to find a satisfying virtiofsd"
solution:
Clone the virtiofs rust repository & install Rust:
git clone https://gitlab.com/virtio-fs/virtiofsd
sudo apt install libcap-ng-dev libseccomp-dev
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup

Go to the cloned repository & build with Rust:
cd virtiofsd
cargo build --release

Open virt-manager:
Enable xml editing from virt-manager -> Edit -> Preferences -> Enable XML editing

Open Kali-domain from virt-manager and open the "Show virtual hardware details":
Memory -> Enable shared memory

Now add the Filesystem and then edit the XML and add the following (image of full xml below):
<binary path="path to virtiofsd executable/>
```
![image](https://github.com/lsuutari19/network_sec_platform/assets/55877405/493d6f20-68a8-47f2-9a44-3cc2b1bbcff7)

