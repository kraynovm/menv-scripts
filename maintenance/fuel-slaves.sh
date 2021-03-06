#!/bin/bash

source $PATH_TO_ENV/env.cfg

for i in $(seq 1 $slaves_count)
do
	if [ -z ${slave_name[$i]} ]
	then
		VM_NAME=$vm_prefix-slave-$i
	else
		VM_NAME=$vm_prefix-${slave_name[$i]}
	fi

	if [ $i -lt 10 ]
	then
		MACNUM="0$i"
	else
		MACNUM=$i
	fi
	
	virt_net_params=""
	for j in $(seq 1 $networks)
	do
		if [ -z ${subnet_name[$j]} ]
		then
			net_name=$net_prefix-$j
		else
			net_name=$net_prefix-${subnet_name[$j]}
		fi

		virt_net_params="$virt_net_params --bridge=$net_name,mac=${subnet_mac_prefix[$j]}:$MACNUM"
	done

	if [ -z ${node_disks[$i]} ]
	then
		if [ -z $default_disks ]
		then
			node_disks[$i]=1
		else
			node_disks[$i]=$default_disks
		fi
	fi

	virt_disks_params=""
	for j in $(seq 1 ${node_disks[$i]})
	do
		virt_disks_params="$virt_disks_params --disk path=$PATH_TO_ENV/fuel-slave-$i-$j.qcow2,bus=virtio,device=disk,format=qcow2"
	done

	if [ -z ${slave_ram[$i]} ]
	then
		if [ -z $default_ram ]
		then
			slave_ram[$i]=1024
		else
			slave_ram[$i]=$default_ram
		fi
	fi

	if [ -z ${slave_vcpus[$i]} ]
	then
		if [ -z $default_vcpus ]
		then
			slave_vcpus[$i]=1
		else
			slave_vcpus[$i]=$default_vcpus
		fi
	fi

	sudo virt-install -n $VM_NAME \
	 -r ${slave_ram[$i]} \
	 --vcpus=${slave_vcpus[$i]} \
	 --arch=x86_64 \
	 $virt_disks_params \
	 $virt_net_params \
	 --boot network \
	 --noautoconsole \
	 --graphics vnc,listen=0.0.0.0
	if [ $? -ne 0 ]
	then
		echo "Error encountered while launching a VM: terminating."
		echo "Note: you may want to launch destroy-env.sh script to clear the networks/incomplete vms."
		exit 1
	fi
	
	echo -n $VM_NAME
	virsh vncdisplay $VM_NAME
done
