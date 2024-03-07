#!/bin/bash

echo "Starting cleanup..."

# destroy the VMs
sudo virsh destroy pfsense-domain
sudo virsh undefine pfsense-domain --remove-all-storage

sudo virsh destroy ubuntu-domain
sudo virsh undefine ubuntu-domain --remove-all-storage

sudo virsh destroy kali-domain
sudo virsh undefine kali-domain --remove-all-storage

result=$(sudo virsh list --all)
if [[ $result == *pfsense-domain* || $result == *ubuntu-domain* || $result == *kali-domain* ]]; then
    echo "VM domains could not be destroyed."
    exit 1;
else
    echo "VM domains have been destroyed."
fi

# Command to destroy the virtual network
sudo virsh net-destroy external_network
sudo virsh net-undefine external_network
sudo virsh net-destroy internal_network
sudo virsh net-undefine internal_network
sudo virsh net-destroy demilitarized_zone
sudo virsh net-undefine demilitarized_zone

result=$(sudo virsh net-list --all)
if [[ $result == *_network* ]]; then
    echo "Virtual networks could not be destroyed."
    exit 1;
else
    echo "VM networks have been destroyed."
fi

# # Command to destroy the pool storage
# sudo virsh pool-destroy default_pool
# sudo virsh pool-undefine default_pool

# result=$(sudo virsh pool-list --all)
# if [[ $result == *default_pool* ]]; then
#     echo "VM pool storages could not be destroyed."
#     exit 1;
# else
#     echo "VM pool storages have been destroyed."
# fi


# Command to delete volumes
sudo virsh vol-delete  $PWD/volumes/pfsense-commoninit.iso
sudo virsh vol-delete $PWD/volumes/pfsense-volume
sudo virsh vol-delete $PWD/volumes/ubuntu-commoninit.iso
sudo virsh vol-delete $PWD/volumes/ubuntu-volume
sudo virsh vol-delete $PWD/volumes/kali-commoninit.iso
sudo virsh vol-delete  $PWD/volumes/kali-volume


result=$(sudo virsh vol-list --pool default_pool)
if [[ $result == *.iso* || $result == *.qcow2* ]]; then
    echo "VM volumes could not be deleted."
    exit 1;
else
    echo "VM volumes have been destroyed."
fi

# Command to delete ISO file
# sudo virsh vol-delete /tmp/terraform-provider-libvirt-pool/vm_cloudinit.iso

rm terraform.tfstate
rm terraform.tfstate.backup

echo "Cleanup completed."
exit 0
