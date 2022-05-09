#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
Green_font="\033[32m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
echo -e "${Green_font}
#======================================
# Project: vps_traceroute_speed_bench
# Version: 1.0
# Author: ccgakki
#======================================
${Font_suffix}"

#set language utf-8
export LC_ALL="en_US.utf8"

check_system(){
	if   [[ ! -z "`cat /etc/issue | grep -iE "debian"`" ]]; then
		apt-get install traceroute mtr unzip -y
	elif [[ ! -z "`cat /etc/issue | grep -iE "ubuntu"`" ]]; then
		apt-get install traceroute mtr unzip -y
	elif [[ ! -z "`cat /etc/redhat-release | grep -iE "CentOS"`" ]]; then
		yum install traceroute mtr unzip -y
	else
		echo -e "${Error} system not support!" && exit 1
	fi
}
check_root(){
	[[ "`id -u`" != "0" ]] && echo -e "${Error} must be root user !" && exit 1
}

install_worsttrace(){
	[[ ! -f /usr/local/bin/worsttrace ]] && wget https://pkg.wtrace.app/linux/worsttrace -O /usr/local/bin/worsttrace
	[[ ! -f /usr/local/bin/worsttrace ]] && echo -e "${Error} download failed, please check!" && exit 1
	chmod a+x /usr/local/bin/worsttrace
}

install_speedtest(){
    if  [ ! -e './speedtest-cli/speedtest' ]; then
      echo "正在安装 Speedtest-cli"

    else
      echo "已经安装，请先卸载"
      apt-get remove speedtest ; yum remove speedtest
      exit
    fi
    if  [[ ${release} == debian || ${release} == ubuntu ]] ; then
      curl -s https://install.speedtest.net/app/cli/install.deb.sh | bash
      apt-get install speedtest
    elif [ ${release} == "centos" ] ; then
      curl -s https://install.speedtest.net/app/cli/install.rpm.sh |  bash
      yum install speedtest
    else
      echo "不是合适的版本"
      exit
    fi
}

select_speedtest() {
	echo -e "  测速类型:    ${GREEN}1.${PLAIN} VPS本地+国内三网+国际测速    ${GREEN}2.${PLAIN} 返回主菜单"
	echo -ne "               ${GREEN}3.${PLAIN} 电信节点    ${GREEN}4.${PLAIN} 联通节点    ${GREEN}5.${PLAIN} 移动节点"
	while :
  do echo
			read -p "  请输入数字选择测速类型: " selection
			if [[ ! $selection =~ ^[1-5]$ ]]; then
					echo -ne "  ${RED}输入错误${PLAIN}, 请输入正确的数字!"
			else
					break   
			fi
	done
  if [[ $selection == 2]]
   then
      start_vtsb
  else
      runtest
  fi
}

speed_test(){
	speedLog="./speedtest.log"
	true > $speedLog
		speedtest -p no -s $1 --accept-license > $speedLog 2>&1
		is_upload=$(cat $speedLog | grep 'Upload')
		if [[ ${is_upload} ]]; then
	        local REDownload=$(cat $speedLog | awk -F ' ' '/Download/{print $3}')
	        local reupload=$(cat $speedLog | awk -F ' ' '/Upload/{print $3}')
	        local relatency=$(cat $speedLog | awk -F ' ' '/Latency/{print $2}')
	        
			local nodeID=$1
			local nodeLocation=$2
			local nodeISP=$3
			
			strnodeLocation="${nodeLocation}　　　　　　"
			LANG=C
			#echo $LANG
			
			temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
	        if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
	        	printf "${RED}%-6s${YELLOW}%s%s${GREEN}%-24s${CYAN}%s%-10s${BLUE}%s%-10s${PURPLE}%-8s${PLAIN}\n" "${nodeID}"  "${nodeISP}" "|" "${strnodeLocation:0:24}" "↑ " "${reupload}" "↓ " "${REDownload}" "${relatency}" | tee -a $log
			fi
		else
	        local cerror="ERROR"
		fi
}

runtest() {
	#[[ ${selection} == 2 ]] && exit 1

	if [[ ${selection} == 1 ]]; then
		echo "——————————————————————————————————————————————————————————"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 
    
    #***
		 speed_test '3633' '上海' '电信'
		 speed_test '41852' '河南郑州' '电信'
		 speed_test '27377' '北京５Ｇ' '电信'
		 speed_test '26352' '江苏南京５Ｇ' '电信'
    #***
		 speed_test '24447' '上海５Ｇ' '联通'
		 speed_test '27154' '天津５Ｇ' '联通'
		 speed_test '13704' '江苏南京' '联通'
		 speed_test '5485' '湖北武汉' '联通'
		#***
		 speed_test '25858' '北京' '移动'
		 speed_test '26404' '安徽合肥５Ｇ' '移动'
		 speed_test '17584' '重庆' '移动'
		 speed_test '29105' '陕西西安５Ｇ' '移动'
    #***
     speed_test '' 'Speedtest.net' '本地'
     speed_test '22168' '美国西雅图' 'Whitesky'
     speed_test '46052' '德国' 'Hetzner'
     speed_test '44340' '香港' 'Telstra'
     speed_test '31293' '新加坡' 'Pacific Internet'
     speed_test '28910' '日本' 'fdcservers'

		end=$(date +%s)  
		rm -rf speedtest*
		echo "——————————————————————————————————————————————————————————"
		time=$(( $end - $start ))
		if [[ $time -gt 60 ]]; then
			min=$(expr $time / 60)
			sec=$(expr $time % 60)
			echo -ne "  测试完成, 本次测速耗时: ${min} 分 ${sec} 秒"
		else
			echo -ne "  测试完成, 本次测速耗时: ${time} 秒"
		fi
		echo -ne "\n  当前时间: "
		echo $(date +%Y-%m-%d" "%H:%M:%S)
		echo -e "  ${GREEN}# 三网测速中为避免节点数不均及测试过久，每部分未使用所${PLAIN}"
		echo -e "  ${GREEN}# 有节点，如果需要使用全部节点，可分别选择三网节点检测${PLAIN}"
	fi

	if [[ ${selection} == 3 ]]; then
		echo "——————————————————————————————————————————————————————————"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 

		 speed_test '27377' '北京５Ｇ' '电信'
		 speed_test '29026' '四川成都' '电信'
		 speed_test '41852' '河南郑州5G' '电信'
		 speed_test '17145' '安徽合肥５Ｇ' '电信'
		 speed_test '36663' '江苏镇江５Ｇ' '电信'
		 speed_test '26850' '江苏无锡５Ｇ' '电信'
		 speed_test '29353' '湖北武汉５Ｇ' '电信'
		 speed_test '28225' '湖南长沙５Ｇ' '电信'

		end=$(date +%s)  
		rm -rf speedtest*
		echo "——————————————————————————————————————————————————————————"
		time=$(( $end - $start ))
		if [[ $time -gt 60 ]]; then
			min=$(expr $time / 60)
			sec=$(expr $time % 60)
			echo -ne "  测试完成, 本次测速耗时: ${min} 分 ${sec} 秒"
		else
			echo -ne "  测试完成, 本次测速耗时: ${time} 秒"
		fi
		echo -ne "\n  当前时间: "
		echo $(date +%Y-%m-%d" "%H:%M:%S)
	fi

	if [[ ${selection} == 4 ]]; then
		echo "——————————————————————————————————————————————————————————"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 

		 speed_test '21005' '上海' '联通'
		 speed_test '24447' '上海５Ｇ' '联通'
		 speed_test '5103' '云南昆明' '联通'
		 speed_test '5145' '北京' '联通'
		 speed_test '5505' '北京' '联通'
		 speed_test '9484' '吉林长春' '联通'
		 speed_test '2461' '四川成都' '联通'
		 speed_test '27154' '天津５Ｇ' '联通'
		end=$(date +%s)  
		rm -rf speedtest*
		echo "——————————————————————————————————————————————————————————"
		time=$(( $end - $start ))
		if [[ $time -gt 60 ]]; then
			min=$(expr $time / 60)
			sec=$(expr $time % 60)
			echo -ne "  测试完成, 本次测速耗时: ${min} 分 ${sec} 秒"
		else
			echo -ne "  测试完成, 本次测速耗时: ${time} 秒"
		fi
		echo -ne "\n  当前时间: "
		echo $(date +%Y-%m-%d" "%H:%M:%S)
	fi

	if [[ ${selection} == 5 ]]; then
		echo "——————————————————————————————————————————————————————————"
		echo "ID    测速服务器信息       上传/Mbps   下载/Mbps   延迟/ms"
		start=$(date +%s) 

		 speed_test '25637' '上海５Ｇ' '移动'
		 speed_test '26728' '云南昆明' '移动'
		 speed_test '25881' '山东济南５Ｇ' '移动'
		 speed_test '6611' '广东广州' '移动'
		 speed_test '27249' '江苏南京５Ｇ' '移动'
		 speed_test '17223' '河北石家庄' '移动'
		 speed_test '44176' '河南郑州５Ｇ' '移动'
		 speed_test '4647' '浙江杭州' '移动'

		end=$(date +%s)  
		rm -rf speedtest*
		echo "——————————————————————————————————————————————————————————"
		time=$(( $end - $start ))
		if [[ $time -gt 60 ]]; then
			min=$(expr $time / 60)
			sec=$(expr $time % 60)
			echo -ne "  测试完成, 本次测速耗时: ${min} 分 ${sec} 秒"
		else
			echo -ne "  测试完成, 本次测速耗时: ${time} 秒"
		fi
		echo -ne "\n  当前时间: "
		echo $(date +%Y-%m-%d" "%H:%M:%S)
	fi
  start_vtsb
}

start_speedtest(){

}

test_single(){
	echo -e "${Info} 请输入你要测试的目标 ip :"
	read -p "输入 ip 地址:" ip

	while [[ -z "${ip}" ]]
		do
			echo -e "${Error} 无效输入"
			echo -e "${Info} 请重新输入" && read -p "输入 ip 地址:" ip
		done

	worsttrace ${ip} | grep -v -E 'WorstTrace|Join'

	repeat_test_single
}

repeat_test_single(){
	echo -e "${Info} 是否继续测试其他目标 ip ?"
	echo -e "1.是\n2.回主菜单"
	read -p "请选择:" whether_repeat_single
	while [[ ! "${whether_repeat_single}" =~ ^[1-3]$ ]]
		do
			echo -e "${Error} 无效输入"
			echo -e "${Info} 请重新输入" && read -p "请选择:" whether_repeat_single
		done
	[[ "${whether_repeat_single}" == "1" ]] && test_single
	[[ "${whether_repeat_single}" == "2" ]] && echo -e "${Info} 回主菜单 ..." && start_vtsb
}



test_alternative(){
	select_alternative
	set_alternative
	result_alternative
}
select_alternative(){
	echo -e "${Info} 选择需要测试的目标网络: \n1.中国电信\n2.中国联通\n3.中国移动\n4.教育网"
	read -p "输入数字以选择:" ISP

	while [[ ! "${ISP}" =~ ^[1-4]$ ]]
		do
			echo -e "${Error} 无效输入"
			echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" ISP
		done
}
set_alternative(){
	[[ "${ISP}" == "1" ]] && node_1
	[[ "${ISP}" == "2" ]] && node_2
	[[ "${ISP}" == "3" ]] && node_3
	[[ "${ISP}" == "4" ]] && node_4
}
node_1(){
	echo -e "1.上海电信(天翼云)\n2.厦门电信CN2\n3.湖北襄阳电信\n4.江西南昌电信\n5.广东深圳电信\n6.广州电信(天翼云)" && read -p "输入数字以选择:" node

	while [[ ! "${node}" =~ ^[1-6]$ ]]
		do
			echo -e "${Error} 无效输入"
			echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" node
		done

	[[ "${node}" == "1" ]] && ISP_name="上海电信"	       && ip=101.89.132.9
	[[ "${node}" == "2" ]] && ISP_name="厦门电信CN2"	       && ip=117.28.254.129
	[[ "${node}" == "3" ]] && ISP_name="湖北襄阳电信"	     && ip=58.51.94.106
	[[ "${node}" == "4" ]] && ISP_name="江西南昌电信"	     && ip=182.98.238.226
	[[ "${node}" == "5" ]] && ISP_name="广东深圳电信"	     && ip=116.6.211.41
	[[ "${node}" == "6" ]] && ISP_name="广州电信(天翼云)" && ip=14.215.116.1
}
node_2(){
	echo -e "1.西藏拉萨联通\n2.重庆联通\n3.河南郑州联通\n4.安徽合肥联通\n5.江苏南京联通\n6.浙江杭州联通" && read -p "输入数字以选择:" node

	while [[ ! "${node}" =~ ^[1-6]$ ]]
		do
			echo -e "${Error} 无效输入"
			echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" node
		done

	[[ "${node}" == "1" ]] && ISP_name="北京联通" && ip=202.106.46.151
	[[ "${node}" == "2" ]] && ISP_name="上海联通"	 && ip=112.65.63.1
	[[ "${node}" == "3" ]] && ISP_name="河南郑州联通" && ip=61.168.23.74
	[[ "${node}" == "4" ]] && ISP_name="安徽合肥联通" && ip=112.122.10.26
	[[ "${node}" == "5" ]] && ISP_name="江苏南京联通" && ip=58.240.53.78
	[[ "${node}" == "6" ]] && ISP_name="浙江杭州联通" && ip=101.71.241.238
}
node_3(){
	echo -e "1.上海移动\n2.四川成都移动\n3.安徽合肥移动\n4.浙江杭州移动\n5.广东深圳移动\n6.北京移动" && read -p "输入数字以选择:" node

	while [[ ! "${node}" =~ ^[1-4]$ ]]
		do
			echo -e "${Error} 无效输入"
			echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" node
		done

	[[ "${node}" == "1" ]] && ISP_name="上海移动"     && ip=221.130.188.251
	[[ "${node}" == "2" ]] && ISP_name="四川成都移动" && ip=183.221.247.9
	[[ "${node}" == "3" ]] && ISP_name="安徽合肥移动" && ip=120.209.140.60
	[[ "${node}" == "4" ]] && ISP_name="浙江杭州移动" && ip=112.17.0.106
  [[ "${node}" == "5" ]] && ISP_name="广东深圳移动" && ip=120.233.73.1
  [[ "${node}" == "6" ]] && ISP_name="北京移动" && ip=221.179.155.161
}
node_4(){
	ISP_name="北京教育网" && ip=202.205.6.30
}
result_alternative(){
	echo -e "${Info} 测试路由 到 ${ISP_name} 中 ..."
	worsttrace ${ip} | grep -v -E 'WorstTrace|Join'
	echo -e "${Info} 测试路由 到 ${ISP_name} 完成 ！"

	repeat_test_alternative
}
repeat_test_alternative(){
	echo -e "${Info} 是否继续测试其他节点?"
	echo -e "1.是\n2.否"
	read -p "请选择:" whether_repeat_alternative
	while [[ ! "${whether_repeat_alternative}" =~ ^[1-2]$ ]]
		do
			echo -e "${Error} 无效输入"
			echo -e "${Info} 请重新输入" && read -p "请选择:" whether_repeat_alternative
		done
	[[ "${whether_repeat_alternative}" == "1" ]] && test_alternative
	[[ "${whether_repeat_alternative}" == "2" ]] && echo -e "${Info} 回到主菜单 ..." && start_vtsb
}

start_bench(){
  echo "咕咕咕"
  start_vtsb
}

start_all(){
  echo "咕咕咕"
  start_vtsb
}

test_all(){
	result_all	'58.32.32.1'	    '上海CN2'
	result_all	'101.95.110.149'	'上海电信'
	result_all	'112.65.63.1'		  '上海联通'
	result_all	'210.13.66.238'		'上海联通9929'
	result_all	'120.197.96.1'		'广州移动120'
	result_all	'183.232.226.1'	  '广州移动183'
	result_all	'202.205.6.30'		'北京教育网'
	echo -e "${Info} 四网路由快速测试 已完成 ！"
}
result_all(){
	ISP_name=$2
	echo -e "${Info} 测试路由 到 ${ISP_name} 中 ..."
	worsttrace $1 | grep -v -E 'WorstTrace|Join'
	echo -e "${Info} 测试路由 到 ${ISP_name} 完成 ！"
}

start_vtsb(){
echo -e "${Info} 选择你要使用的功能: "
echo -e "1.选择一个节点进行路由测试\n2.四网路由快速测试\n3.手动输入ip路由测试\n4.VPS带宽测试\n5.VPS Bench性能测试\n6.VTSB测试"
read -p "输入数字以选择:" function

	while [[ ! "${function}" =~ ^[1-5]$ ]]
		do
			echo -e "${Error} 缺少或无效输入"
			echo -e "${Info} 请重新选择" && read -p "输入数字以选择:" function
		done

	if [[ "${function}" == "1" ]]; then
		test_alternative
	elif [[ "${function}" == "2" ]]; then
		test_all
	else [[ "${function}" == "3"]]; then
		test_single
  else [[ "${function}" == "4"]]; then
		select_speedtest
  else [[ "${function}" == "5"]]; then
		start_bench
  else [[ "${function}" == "6"]]; then
		start_all
	fi
}

apt install wget -y ; yum install wget -y
check_system
check_root
install_worsttrace
install_speedtest
start_vtsb

