#!/bin/sh

ISO=/Users/mat/Desktop/Not\ Backed\ Up/OS/ubuntu-10.04.3-desktop-amd64.iso
NAME=UbuntuTest
TYPE=Ubuntu_64
MEMORY=1024
DISK=5120

VMS=`pwd`/vms
HD=$VMS/$NAME/$NAME.vmdk

host_interface() {
  echo `VBoxManage list hostonlyifs | grep -e ^Name | awk '{print $2}'`
}

if [[ -z `host_interface` ]]; then
  VBoxManage hostonlyif create
  VBoxManage hostonlyif ipconfig `host_interface` --dhcp
fi

# Credit: http://www.bloof.de/virtualBox_headless

VBoxManage createvm --name "$NAME" --ostype "$TYPE" --register --basefolder "$VMS"
VBoxManage modifyvm "$NAME" --memory "$MEMORY" --acpi on

VBoxManage modifyvm "$NAME" --nic1 nat
VBoxManage modifyvm "$NAME" --nic2 hostonly --hostonlyadapter2 `host_interface`

VBoxManage storagectl "$NAME" --name 'IDE Controller' --add ide
VBoxManage storagectl "$NAME" --name 'SATA Controller' --add sata --sataportcount 1

VBoxManage createhd --filename "$HD" --size "$DISK" --format VMDK

VBoxManage storageattach "$NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$ISO"
VBoxManage storageattach "$NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$HD"

# VBoxManage startvm "$NAME"

# VBoxManage unregistervm $NAME --delete
