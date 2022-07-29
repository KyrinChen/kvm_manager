#!/bin/bash
#基本管理页面的选单，对应函数集中在functions.sh进行调用，同样要将function.sh放置于同一目录
. functions.sh   #执行导入functions

#选单
PS3="[基本管理]："
while true; do
    select choice in "查看所有KVM" "正在运行的KVM" "开机" "关机" "重启" "强制关机" "删除KVM" "返回上一级"; do
        case ${choice} in
            "查看所有KVM")
                showKvm
                ;;
            "正在运行的KVM")
                showKvmAlived
                ;;
            "开机")
                startKvm
                ;;
            "关机")
                shutdownKvm
                ;;
            "重启")
               rebootKvm
                ;;
            "强制关机")
                destroyKvm
                ;;
            "删除KVM")
                deleteKvm
                ;;
            "返回上一级")
                exit
                ;;
            *)
            echo "暂无此功能，敬请期待！"
        esac
    done
done
