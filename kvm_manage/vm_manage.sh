#!/bin/bash
#虚拟机管理页面的选单，对应函数集中在functions.sh进行调用，同样要将function.sh放置于同一目录
. functions.sh   #执行导入functions

PS3="[虚拟机管理]："
while true; do
	select choice in  "通过配置文件获取信息" "导出虚拟机" "导入虚拟机" "查看KVM硬件信息" "查看真机硬件信息" "返回上一级"; do
		case ${choice} in
			"通过配置文件获取信息")
				getConfig
				;;
			"导出虚拟机")
				exportKvm
				;;
			"导入虚拟机")
				importKvm
				;;
			"查看KVM硬件信息")
				showVirtualMachineInfo
				;;
			"查看真机硬件信息")
				showPhysicalMachineIfo
				;;
			"返回上一级")
				exit
				;;
		    *)
				echo "暂无此功能，敬请期待！"
		esac
	done
done


