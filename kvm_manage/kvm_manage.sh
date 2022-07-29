#!/bin/bash
#主控制页面，选择不同的功能块时，会执行并跳转到对应的功能块，前提是其实的脚本要与此脚本放在同一个目录

echo "++++++++++++++欢迎使用KVM管理工具+++++++++++++++++++"
PS3="【KVM管理[主菜单]】："
while true; do
    select choice in "基本管理" "虚拟机管理" "快照" "退出"; do
        case ${choice} in
            "基本管理")
                bash ./basic_manage.sh
                ;;
            "虚拟机管理")
                bash ./vm_manage.sh
                ;;
            "快照")
                bash ./snapshot.sh
                ;;
            "退出")
                exit
                ;;
            *)
            echo "暂无此功能，敬请期待！"
        esac
    done
done



