#!/bin/bash
#快照页面的选单，对应函数集中在functions.sh进行调用，同样要将function.sh放置于同一目录
. functions.sh   #执行导入functions

PS3="[快照]："
while true; do
	select choice in "磁盘格式转换raw->qcow2" "拍摄快照" "恢复快照" "删除快照" "查看快照" "返回上一级"; do
		case ${choice} in
			"磁盘格式转换raw->qcow2")
				convertQcow2
				;;
			"拍摄快照")
				makeSnapshot
				;;
			"恢复快照")
				recoverSnapshot
				;;
			"删除快照")
				deleteSnapshot
				;;
			"查看快照")
				findSnapshot
				;;
			"返回上一级")
				exit
				;;
		    *)
				echo "暂无此功能，敬请期待！"
		esac
	done
done


