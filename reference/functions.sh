#!/bin/bash
#kvm所有功能的核心部分，所有的函数都存储在这个文件

#=======================================基本管理功能========================================================

#查看所有kvm
showKvm(){ 
	list1=(`virsh list --all|awk 'NR>=3{print $2}'`)  #将所有kvm的名称做成一个列表，方便后面调用
	[ ${#list1[*]} -ne 0 ] && virsh list --all  || echo "当前没有任何KVM可以管理。"   #列表为空时说明没有还没有kvm
}
#查看所有正在运行的kvm
showKvmAlived(){
    list2=(`virsh list|awk 'NR>=3{print $2}'`)        #将所有的正在运行的kvm做成列表，方便后面调用
    result=${#list2[*]}
    if [ ${result} -eq 0 ];then
        echo "当前没有KVM在运行。"
    else
        virsh list
    fi
}
#关闭kvm
shutdownKvm(){
    showKvmAlived &> /dev/null                         #先调用showKvmAlived函数，可以获得函数内的列表等，用于后续判断
    if [ ${result} -eq 0 ];then						   #showKvmAlived函数的result，如果为0，直接退出，不进行任何判断
        echo "当前没有KVM在运行。"
    else
        echo "当前正在运行的KVM：${list2[*]}"
        read -p "请输入您要关闭的KVM：" name
		flag=0      #定义一个标志，如果最后这个标志没有改变，则说明输入的kvm不在运行列表中
        for i in `seq 0 ${#list2[*]}`;do            #遍历对比，看看用户输入的名称是否存在
            listName=${list2[$i]}
            [[ "${name}" == "${listName}" ]] && virsh shutdown ${name} && flag=1 && break    #若成功关机，则改变flag的值
        done
		[ ${flag} -eq 0 ] && echo "关机失败！此KVM没有在运行。"      #通过flag判断告知结果
        
    fi
}
#启动kvm
startKvm(){
	showKvm > /dev/null                                      #以下类似的调用的作用都是一样的
	if [ ${#list1[*]} -eq 0 ];then
	    echo "当前没有任何KVM可以启动。"
	else
		echo "当前拥有的KVM：${list1[*]}"
		read -p "请输入您要开启的KVM：" name
		flag=0
        for i in `seq 0 ${#list1[*]}`;do
            listName=${list1[$i]}
            [[ "${name}" == "${listName}" ]] && virsh start ${name} && flag=1 && break
        done
        [ ${flag} -eq 0 ] && echo "开机失败！此KVM不存在或正在运行。"                 #正在运行或不存在的kvm无法执行开机操作
    fi
}
#重启kvm
rebootKvm(){
	showKvmAlived &> /dev/null
        if [ ${result} -eq 0 ];then
            echo "当前没有KVM在运行。"
        else
            echo "当前正在运行的KVM：${list2[*]}"
            read -p "请输入您要重启的KVM：" name
			flag=0
            for i in `seq 0 ${#list2[*]}`;do
                listName=${list2[$i]}
                [[ "${name}" == "${listName}" ]] && virsh reboot ${name} && flag=1 && break
            done
            [ ${flag} -eq 0 ] && echo "重启失败！此KVM没有在运行。" #这里实际上缺少一个对于输入的名称是否存在与kvm名单的判断，不过不影响功能实现
        fi
}
#强制关闭kvm
destroyKvm(){
	showKvmAlived &> /dev/null
        if [ ${result} -eq 0 ];then
            echo "当前没有KVM在运行。"
        else
            echo "当前正在运行的KVM：${list2[*]}"
            read -p "请输入您要强制关闭的KVM：" name
			flag=0
            for i in `seq 0 ${#list2[*]}`;do
                listName=${list2[$i]}
                [[ "${name}" == "${listName}" ]] && virsh destroy ${name} && flag=1 && break
            done
            [ $flag -eq 0 ] && echo "强制关机失败！此KVM没有在运行。"   #强制重启动作只能作用与已经处于运行状态的kvm
        fi
}
#删除kvm
deleteKvm(){
	read -p "请输入您要删除的KVM：" name
	read -p "此操作不可逆，您确定要进行删除吗？【Y/N】" answer1    #确认删除
	case ${answer1} in
	Y|y)
		showKvmAlived &> /dev/null
		showKvm &> /dev/null
		for i in ${list1[*]};do                 #检查输入的名称是否属于已存在的kvm
			if [ "${i}" == "${name}" ];then
				flag=0                            #flag标志和mark标志都是为了方便后面的判断
				mark=0
				for j in ${list2[*]};do               #若输入的名称属于已存在的kvm，则继续检查此kvm是否处于运行状态
					[ "${j}" == "${name}" ] && echo "${name} 正在运行，无法直接删除，请先停止机器。" && flag=1 && break
				done
				#检查该机器是否为链接克隆的原机器
				[ -e ./cloneRelationship ] && checkClone=($(awk -F"[ |.]" '/^A/{print $5}' ./cloneRelationship))
				for x in ${checkClone[*]};do
					#判断要删除的机器是否为链接克隆的源机器，是源机器则不能删除
					[[ "${x}" == "${name}" ]] && echo "注意： ${name} 是链接克隆的源机器，删除后其克隆机将不可用。若您确实希望删除此机器，请您先处理其链接克隆的机器。" && flag=2 && break
				done
				if [ ${flag} -eq 0 ];then                #flag的值若没有被改变，则说明满足删除KVM的条件
					flag=1                              #判断完之后要马上将flag的值变成非0值，否则一旦执行了一次成功的删除，flag的值就会一直是0，影响后面判断
					diskName=(`virsh domblklist $name|awk 'NR>=3{print $2}'`)      #先获取kvm的磁盘文件再执行删除动作，否则先删除的话就无法使用domblklist命令获取
					virsh undefine ${name}  &> /dev/null
					[ -e ./cloneRelationship ] && sed -ri "/${name} /d" cloneRelationship  #要先判断一下这个文件是否存在，若不存在则说明当前还没有克隆关系
					rm -rf /var/lib/libvirt/qemu/snapshot/${name}/    &> /dev/null                #删除该机器相关的快照文件
					read -p "已为您删除$name，您要删除$name的磁盘文件吗？【Y/N】" answer2    #undefine不会删除相应的磁盘文件，需要下一步操作
					case ${answer2} in
					Y|y)
						for n in ${diskName[*]};do                   #一台kvm的可能有多个磁盘，也就是多个磁盘文件，这里是直接把对应的磁盘文件全都删除了
							rm -rf ${n}
						done
						echo "已为您删除磁盘文件。"
						;;
					N|n)
						echo "磁盘文件已保留，您可以通过磁盘文件恢复此KVM的数据"
						;;
					*)
						echo "输入有误，请手动删除${name}的磁盘文件，否则磁盘文件将保留。"
					esac
				fi
			fi
		done
		[ "${mark}" != "0" ] && echo "$name 不存在！"
		mark=1			#mark如果没有被改变，则说明不存在该名称的kvm,用完之后要将mark改成非0，否则成功删除一次之后，他就一直是0了，影响后面的判断
		;;
	N|n)
		echo "已取消删除操作"
		;;
	*)
		echo "输入有误，请输入<Y/y|N/n>"
	esac
}

#=======================================克隆功能========================================================

#完整克隆
fullClone(){
	showKvm &> /dev/null  # 把函数的输出重定向到/dev/null使得输出为空
	if [ ${#list1[*]} -eq 0 ];then
		echo "当前没有任何KVM可以克隆。"
	else
		echo "当前可以克隆的机器有：${list1[*]}"     #提示当前可进行克隆的机器
		read -p "请输入您要克隆的机器：" ori_machine
		read -p "请输入新机器的名字：" new_machine
		check1=0
		check2=1
        for i in `seq 0 ${#list1[*]}`;do 
            listName=${list1[$i]}
            [[ "${ori_machine}" == "${listName}" ]]  && check1=1   #克隆的原机器必须要存在
			[[ "${new_machine}" == "${listName}" ]]  && check2=0   #新的机器名称不能与已存在的机器冲突
        done
	fi
	if [[ ${check1} -eq 1  && ${check2} -eq 1 ]];then               #两个条件要同时满足才能进行克隆
		echo "完整克隆需要一点时间，请稍后..."
		cp /etc/libvirt/qemu/${ori_machine}.xml /etc/libvirt/qemu/${new_machine}.xml		#创建xml文件
		#对xml文件进行对应的修改
		sed -ri "/<name>/ s/(<.*>)(.*)(<.*)/\1$new_machine\3/" /etc/libvirt/qemu/${new_machine}.xml  #修改名字
		new_uuid=$(uuidgen)
		sed -ri "/uuid/ s/(<.*>)(.*)(<.*)/\1$new_uuid\3/" /etc/libvirt/qemu/${new_machine}.xml        #修改UUID
		sed -ri "/source file/ s/(.*)($ori_machine)(.*)/\1$new_machine\3/p" /etc/libvirt/qemu/${new_machine}.xml  #修改文件路径
		sed -ri "/mac add/d" /etc/libvirt/qemu/${new_machine}.xml                                                 #修改mac地址，直接删除，克隆后会自动生成
		cp /var/lib/libvirt/images/${ori_machine}.img /var/lib/libvirt/images/${new_machine}.img                   #复制磁盘文件
		virsh define /etc/libvirt/qemu/${new_machine}.xml &> /dev/null                                             #克隆
		echo "$new_machine克隆成功!"
		echo "F 完整克隆： ${new_machine} 来自 ${ori_machine}." >> ./cloneRelationship                                #将克隆关系写入文件保存，方便其他功能进行调用
	elif [[ ${check1} -eq 0 ]];then
		echo "克隆失败！${ori_machine}不存在！"
	else
		echo "克隆失败！${new_machine}已存在！"
	fi
}
#增量克隆
addClone(){
	showKvm &> /dev/null                                                #增量克隆的思路和完整克隆的思路是一样的
	if [ ${#list1[*]} -eq 0 ];then
		echo "当前没有任何KVM可以克隆。"
	else
		echo "当前可以克隆的机器有：${list1[*]}"
		read -p "请输入您要克隆的机器：" ori_machine
		read -p "请输入新机器的名字：" new_machine
		check1=0
		check2=1
        for i in `seq 0 ${#list1[*]}`;do 
            listName=${list1[$i]}
            [[ "${ori_machine}" == "${listName}" ]]  && check1=1
			[[ "${new_machine}" == "${listName}" ]]  && check2=0
        done
	fi
	if [[ ${check1} -eq 1  && ${check2} -eq 1 ]];then
		cp /etc/libvirt/qemu/${ori_machine}.xml /etc/libvirt/qemu/${new_machine}.xml
		sed -ri "/<name>/ s/(<.*>)(.*)(<.*)/\1$new_machine\3/" /etc/libvirt/qemu/${new_machine}.xml
		new_uuid=$(uuidgen)
		sed -ri "/uuid/ s/(<.*>)(.*)(<.*)/\1$new_uuid\3/" /etc/libvirt/qemu/${new_machine}.xml
		sed -ri "/source file/ s/(.*)($ori_machine)(.*)/\1$new_machine\3/p" /etc/libvirt/qemu/${new_machine}.xml
		sed -ri "/mac add/d" /etc/libvirt/qemu/${new_machine}.xml
		qemu-img create -f qcow2 -b /var/lib/libvirt/images/${ori_machine}.img /var/lib/libvirt/images/${new_machine}.img &> /dev/null
		virsh define /etc/libvirt/qemu/${new_machine}.xml &> /dev/null
		echo "$new_machine克隆成功!"
		echo "A 增量克隆： ${new_machine} 来自 ${ori_machine}." >> ./cloneRelationship
	elif [[ ${check1} -eq 0 ]];then
		echo "克隆失败！${ori_machine}不存在！"
	else
		echo "克隆失败！${new_machine}已存在！"
	fi
}

#查看克隆关系
showCloneRelationship(){
	[ -e ./cloneRelationship ] && sed '' ./cloneRelationship || echo "当前还未产生任何克隆关系。"   #直接读取文件的内容即可
}

#=======================================快照功能========================================================

#拍摄快照
makeSnapshot(){
	showKvm &> /dev/null
	showKvmAlived &> /dev/null
	if [ ${#list1[*]} -eq 0 ];then
		echo "当前没有任何KVM可以拍摄快照。"
	else
		read -p  "请输入需要拍摄快照的机器名称：" name
		read -p  "请输入快照名称："  snapshotName
		for i in ${list1[*]};do 
			if [ "${i}" == "${name}" ];then
				flag=0   
				mark=0
				for j in ${list2[*]};do        #检查该机器是否处于运行状态，不建议对处于运行状态的机器拍摄快照s
					[ "${j}" == "${name}" ] && echo "${name} 正在运行，请您先停止机器再拍摄快照！" && flag=1 && break
				done
				snapshotList=($(virsh snapshot-list ${name}|awk 'NR>=3{count[$1]++}END{for(i in count){print i}}'))  #提取出该机器所有的快照的名称
				for x in ${snapshotList[*]};do
					[[ "${x}" == "${snapshotName}" ]] && echo "该快照已经存在！" && flag=2 && break  #同一机器的快照名称不能重复
				done
				if [ ${flag} -eq 0 ];then               
					flag=1                             
					virsh snapshot-create-as ${name} ${snapshotName}  &> /dev/null                       #拍摄快照
					echo "快照创建成功！"
				fi
			fi
		done
	fi
	[ "${mark}" != "0" ] && echo "$name 不存在！"
	mark=1
}
#恢复快照
recoverSnapshot(){
	showKvm &> /dev/null
	showKvmAlived &> /dev/null
	if [ ${#list1[*]} -eq 0 ];then
		echo "当前没有任何KVM可以进行快照恢复。"
	else
		read -p  "请输入需要恢复快照的机器名称：" name
		read -p  "请输入快照名称："  snapshotName
		for i in ${list1[*]};do 
			if [ "${i}" == "${name}" ];then
				flag=0   
				mark=0
				symbol=0
				for j in ${list2[*]};do
					[ "${j}" == "${name}" ] && echo "${name} 正在运行，请您先停止机器再恢复快照！" && flag=1 && break  #先关机再进行恢复
				done
				snapshotList=($(virsh snapshot-list ${name}|awk 'NR>=3{count[$1]++}END{for(i in count){print i}}'))  #将快照名称提取出来
				for x in ${snapshotList[*]};do
					[[ "${x}" == "${snapshotName}" ]] && symbol=1 && break
				done
				[[ ${symbol} -eq 0 ]] && echo "${snapshotName}不存在！"         #要判断输入的快照是否存在
				if [[ ${flag} -eq 0 && ${symbol} -eq 1 ]];then               
					flag=1
					symbol=0
					virsh snapshot-revert ${name} ${snapshotName}  &> /dev/null
					echo "快照恢复成功！"
				fi
			fi
		done
	fi
	[ "${mark}" != "0" ] && echo "${name} 不存在！"
	mark=1
}
#删除快照
deleteSnapshot(){
	showKvm &> /dev/null
	showKvmAlived &> /dev/null
	if [ ${#list1[*]} -eq 0 ];then
		echo "当前没有任何KVM可以进行快照删除。"
	else
		read -p  "请输入需要删除快照的机器名称：" name
		read -p  "请输入快照名称："  snapshotName
		for i in ${list1[*]};do 
			if [ "${i}" == "${name}" ];then
				flag=0   
				mark=0
				symbol=0
				for j in ${list2[*]};do
					[ "${j}" == "${name}" ] && echo "${name} 正在运行，请您先停止机器再删除快照！" && flag=1 && break
				done
				snapshotList=($(virsh snapshot-list ${name}|awk 'NR>=3{count[$1]++}END{for(i in count){print i}}'))  #将指定的机器的快照名称取出来做成列表
				for x in ${snapshotList[*]};do
					[[ "${x}" == "${snapshotName}" ]] && symbol=1 && break
				done
				[[ ${symbol} -eq 0 ]] && echo "${snapshotName}不存在！"
				[[ ${#snapshotList[*]} -eq 0 ]] && echo "${name}没有快照可删除！"
				if [[ ${flag} -eq 0 && ${symbol} -eq 1 ]];then 
					flag=1
					symbol=0
					virsh snapshot-delete ${name} ${snapshotName}  &> /dev/null
					echo "快照删除成功！"
				fi
			fi
		done
	fi
	[ "${mark}" != "0" ] && echo "${name} 不存在！"
	mark=1
}
#查看快照
findSnapshot(){
	showKvm &> /dev/null
	showKvmAlived &> /dev/null
	if [ ${#list1[*]} -eq 0 ];then
		echo "当前没有KVM可查看。"
	else
		read -p  "请输入需要查看快照的机器名称：" name
		read -p  "请输入快照名称【直接Enter查看所有快照】："  snapshotName
		for i in ${list1[*]};do 
			if [ "${i}" == "${name}" ];then
				mark=0
				symbol=0
				snapshotList=($(virsh snapshot-list ${name}|awk 'NR>=3{count[$1]++}END{for(i in count){print i}}'))
				[[ ${#snapshotList[*]} -eq 0 ]] && echo "${name}还未拍摄过快照。" && break
				if [[ "${snapshotName}" == "" ]];then
					virsh snapshot-list ${name}
				else
					for x in ${snapshotList[*]};do
						[[ "${x}" == "${snapshotName}" ]] && symbol=1 && break
					done
					[[ ${symbol} -eq 0 ]] && echo "${snapshotName}不存在！"
					[[ ${symbol} -eq 1 ]] && virsh snapshot-info ${name} ${snapshotName}
				fi
			fi
		done
	fi
	[ "${mark}" != "0" ] && echo "${name} 不存在！"
	mark=1
}
#=======================================资源变配功能========================================================
#查看真机硬件信息
showPhysicalMachineIfo(){
	#利用命令获取几个主要的有关真机的硬件信息
	numCPU=$(sed -rn '/physical id/p' /proc/cpuinfo|uniq|wc -l)
	memeory_M=$(free -m|awk 'NR==2{print $2}')
	memeory_G=$(free -h|awk 'NR==2{print $2}')
	memeory_K=$(echo "$memeory_M*1024"|bc)
	diskAvailable_k=$(df -T|awk '/root /{print $5}')
	diskAvailable_G=$(df -h|awk '/root /{print $4}'|tr -d "G"})
	echo -e "物理CPU：${numCPU}\n物理内存：${memeory_K}k => ${memeory_M}m => ${memeory_G}G\n磁盘可用容量：${diskAvailable_k}k => ${diskAvailable_G}G"
}
#查看KVM硬件信息
showVirtualMachineInfo(){
	#利用命令获取几个关于某一台kvm机器的硬件信息
	showKvm &> /dev/null
	if [ ${#list1[*]} -eq 0 ];then
		echo "当前没有KVM。"
	else
		read -p  "请输入机器名称：" name
		for i in ${list1[*]};do 
			if [ "${i}" == "${name}" ];then
				mark=0
				numCPU=$(virsh dominfo ${name}|awk '/^CPU\(s\)/{print $2}')
				maxMemeory_k=$(virsh dominfo mini|awk '/Max memory/{print $3}')
				usedMemeory_k=$(virsh dominfo mini|awk '/Used memory/{print $3}')
				maxMemeory_G=$(echo "${maxMemeory_k}/1024"|bc)
				usedMemeory_G=$(echo "${usedMemeory_k}/1024"|bc)
				mainDiskCapacity=$(qemu-img info /var/lib/libvirt/images/mini.img |awk -F"[ |()]" '/virtual size/{print $3,$5"("$6")"}')
				numDisk=$(virsh domblklist ${name}|awk 'NR>=3 && !/hda|^$/{count[$1]++}END{for (i in count){print i}}'|wc -l)
				macList=($(virsh domiflist ${name}|awk 'NR>=3{print $5}'))
				numCard=${#macList[*]}
				echo -e "CPU个数：${numCPU}\n最大内存：${maxMemeory_k}k => ${maxMemeory_G}G\n已使用内存：${usedMemeory_k}k => ${usedMemeory_G}G\n主硬盘容量：${mainDiskCapacity}\n磁盘个数：${numDisk}\n网卡个数：${numCard}"
			fi
		done
	fi
	[ "${mark}" != "0" ] && echo "$name 不存在！"
	mark=1
}
#增加磁盘
addDisk(){
	showKvm &> /dev/null
	showPhysicalMachineIfo &> /dev/null
	if [ ${#list1[*]} -eq 0 ];then
		echo "当前没有KVM。"
	else
		read -p  "请输入机器名称：" name
		diskFileName=${name}-$(date +\%F-\%H-\%M-\%S)    #磁盘文件的命名直接使用时间戳，并没有让用户进行输入
		for i in ${list1[*]};do
			if [ "${i}" == "${name}" ];then
				read -p  "请输入要扩容的容量[只支持单位G]：" capacity         #只支持单位G
				read -p  "请输入盘符【只需输入一个字母[a-z]】：" symbol       #盘符只让用户定义最后一个字母，全名盘符直接根据系统盘的类型进行确定，即只允许用户添加跟系统盘同一类型的磁盘
				mark=0
				check_capacity=0
				check_symbol=0
				break_symbol=0
				if [[ "${capacity}" =~ ^[0-9]+$ ]];then                          #判断用户输入是否为纯数字
					if [[ $(echo "${capacity} > ${diskAvailable_G}" | bc) -eq 1 ]];then  #判断添加的磁盘容量是否已经超出真机的磁盘可用容量
						echo "您添加的磁盘容量已经超出物理机的磁盘可用容量，添加失败！" && break
					else
						check_capacity=1   #如果满足条件，打上标签
					fi
				else
					echo "输入有误！请输入数字！" && break
				fi
				diskSymbol=($(virsh domblklist ${name} | awk 'NR>=3 && !/hda|^$/{print $1}'))  #将目标kvm的所有磁盘盘符做成列表
				bus_symbol=${diskSymbol[0]::1}  #截取系统盘盘符的第一个字母
				if [[ "${symbol}" =~ ^[a-z]$ ]];then   #判断用户输入的是否是单个英文字符
					for ch in ${diskSymbol[*]};do
						cut_ch=${ch:2:1}  #截出盘符的最后一个字母进行比较
						if [[ "${symbol}" == "${cut_ch}" ]];then
							echo "此盘符已经被占用，请输入其他字母。" && break_symbol=1 && break
						else
							check_symbol=1   #满足条件则打上标签
							if [[ "${bus_symbol}" == "s" ]];then   #根据系统盘盘符的第一个字母确定bus的类型，只支持一下三种类型
								bus=scsi
							elif [[ "${bus_symbol}" == "h" ]];then
								bus=ide
							elif [[ "${bus_symbol}" == "v" ]];then
								bus=virtio
							fi
						fi
					done
				else
					echo "输入有误！请输入[a-z]之间的一个字母!" && break
				fi
				[[ ${break_symbol} -eq 1 ]] && break
			fi
		done
		if [[ ${check_capacity} -eq 1 && ${check_symbol} -eq 1 ]];then  #两个条件都满足则进行磁盘添加
			qemu-img create -f qcow2 /var/lib/libvirt/images/${diskFileName}.img ${capacity}G &> /dev/null  #创建磁盘
			echo "磁盘创建成功！"
			cat > /etc/libvirt/qemu/${diskFileName}.xml <<- eof                 #编写磁盘文件
			<disk type='file' device='disk'>
       			<driver name='qemu' type='qcow2'/> 
       			<source file='/var/lib/libvirt/images/${diskFileName}.img'/>
      			<target dev="${bus_symbol}d${symbol}" bus="${bus}"/>
			</disk>
			eof
			virsh attach-device ${name} /etc/libvirt/qemu/${diskFileName}.xml --persistent &> /dev/null   #添加磁盘
			sleep 2
			echo "磁盘添加成功！"
		fi
	fi
	[ "${mark}" != "0" ] && echo "$name 不存在！"
	mark=1
}

#增加网卡
addCard(){
	showKvm &> /dev/null
	#添加网卡的功能比较单一，没有提供选项给用户，只要kvm存在直接添加一张默认类型的网卡，有待改进
	if [ ${#list1[*]} -eq 0 ];then
		echo "当前没有KVM。"
	else
		read -p  "请输入机器名称：" name
		for i in ${list1[*]};do
			if [ "${i}" == "${name}" ];then
				mark=0
				virsh attach-interface ${name} network default --model virtio --persistent  &> /dev/null
				echo "添加网卡成功！"
			fi
		done
		
	fi
	[ "${mark}" != "0" ] && echo "$name 不存在！"
	mark=1
}

#增加CPU
addCPU(){
	#思路差不多，不写了，没空
	echo "暂无此功能！自己用命令添加吧。"
}

#删除磁盘
deleteDisk(){
	showKvm &> /dev/null
	if [ ${#list1[*]} -eq 0 ];then
		echo "当前没有KVM。"
	else
		read -p  "请输入机器名称：" name
		for i in ${list1[*]};do 
			if [ "${i}" == "${name}" ];then
				mark=0
				echo "${name}的所有盘符如下："
				diskSymbol=($(virsh domblklist ${name} | awk 'NR>=3 && !/hda|^$/{print $1}'))  #获取所有盘符
				echo ${diskSymbol[*]}
				echo "【注意】：盘符可能与实际的磁盘名称不完全对应，删除前请确定正确的对应关系！"
				sleep 2
				read -p  "请输入您要删除的磁盘盘符【只需输入盘符最后一个字母】：" symbol  #依然是使用最后一个字母进行判断
				if [[ "${symbol}" =~ ^[a-z]$ ]];then
					flag=0
					for ch in ${diskSymbol[*]};do
						cut_ch=${ch:2:1}
						if [[ "${symbol}" == "${cut_ch}" ]];then
							[[ "${symbol}" == "a" ]] && echo "${ch}是系统盘，无法删除！" && flag=1 && break  #一般系统盘都是xxa命名的，所以通过a来判断系统盘不能被删除，不过不严谨，有待改进
							read -p "您确定要删除此磁盘吗？【Y/N】" answer2   #重复确认
							case ${answer2} in
							Y|y)
								virsh detach-disk ${name} ${ch} --persistent &> /dev/null 
								echo "磁盘删除成功！" && flag=1 && break
								;;
							N|n)
								echo "已为你取消本次操作！" && flag=1
								;;
							*)
								echo "输入有误！本次操作失败！" && flag=1
							esac
						fi
					done
					[[ ${flag} -eq 0 ]] && echo "此盘符不存在！" && break
				else
					echo "输入有误！请输入[a-z]之间的一个字母!" && break
				fi
				
			fi
		done
	fi
	[ "${mark}" != "0" ] && echo "$name 不存在！"
	mark=1	
}
#删除网卡
deletCar(){
	showKvm &> /dev/null
	if [ ${#list1[*]} -eq 0 ];then
		echo "当前没有KVM。"
	else
		read -p  "请输入机器名称：" name
		for i in ${list1[*]};do
			if [ "${i}" == "${name}" ];then
				mark=0
				echo "${name}的网卡信息如下："
				virsh domiflist ${name}
				read -p "请输入您要删除的网卡的mac地址：" macName
				check_mac=0
				macList=($(virsh domiflist ${name}|awk 'NR>=3{print $5}'))  #获取指定机器的mac地址
				for mac in ${macList[*]};do
					#删除网卡也是基于添加网卡时考虑的，并没有考虑多种类型，有待改进
					[[ "${mac}" == "${macName}" ]] && virsh detach-interface ${name} --type network --mac ${macName} --persistent &> /dev/null && echo "删除网卡成功！" && check_mac=1 && break
				done
			fi
		done
		[[ ${check_mac} -eq 0 ]] && echo "删除网卡失败！无此网卡！"
	fi
	[ "${mark}" != "0" ] && echo "$name 不存在！"
	mark=1
}

#删除CPU
deleteCPU(){
	#思路差不多，不写了，没空
	echo "暂无此功能！自己用命令删除吧。"
}


