#!/bin/bash
#资源变配页面的选单，对应函数集中在functions.sh进行调用，同样要将function.sh放置于同一目录
. functions.sh   #执行导入functions

PS3="[资源变配]："
while true; do
	select choice in "查看真机硬件信息" "查看KVM硬件信息" "增加磁盘" "增加网卡" "增加CPU" "删除磁盘" "删除网卡" "删除CPU" "返回上一级"; do
		case ${choice} in
			"查看真机硬件信息")
				showPhysicalMachineIfo
				;;
			"查看KVM硬件信息")
				showVirtualMachineInfo
				;;
			"增加磁盘")
				addDisk
				;;
			"增加网卡")
				addCard
				;;
			"增加CPU")
				addCPU
				;;
			"删除磁盘")
				deleteDisk
				;;
			"删除网卡")
				deletCar
				;;
			"删除CPU")
				deleteCPU
				;;
			"返回上一级")
				exit
				;;
		    *)
				echo "暂无此功能，敬请期待！"
		esac
	done
done


