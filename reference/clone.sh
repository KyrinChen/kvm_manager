#!/bin/bash
#克隆页面的选单，对应函数集中在functions.sh进行调用，同样要将function.sh放置于同一目录
. functions.sh   #执行导入functions

PS3="[克隆]："
while true; do
	select choice in "完整克隆" "增量克隆" "查看克隆关系" "返回上一级"; do
		case ${choice} in
			"完整克隆")
				fullClone
				;;
			"增量克隆")
				addClone
				;;
			"查看克隆关系")
				showCloneRelationship
				;;
			"返回上一级")
				exit
				;;
		    *)
				echo "暂无此功能，敬请期待！"
		esac
	done
done
