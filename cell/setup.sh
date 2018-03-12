#!/bin/sh

CELLV='0'
CELLHUB="ianki.cn:1338"
NETNAME=""
HOSTNAME=""

set_timezone() {
  # https://wiki.openwrt.org/doc/uci/system#time_zones
  uci set system.@system[0].timezone="CST-8"
  uci commit system
}

# set the version number
set_version() {
  uci set system.@system[0].cellv=${CELLV}
  uci commit system
}

set_cellhub() {
  uci set system.@system[0].cellhub=${CELLHUB}
  uci commit system
}

# install tinc & config
set_tinc() {
  echo -e "\n>> Set tinc"

  # must assign a unique id(as netname) & ip address to this router
  local node=$1
  local ip_addr=$2
  local net_addr=$3

  echo $node
  echo $ip_addr
  echo $net_addr

  # remove the old file anyway.
  local net_dir=/etc/tinc/${NETNAME}
  rm -rf ${net_dir}
  mkdir -p ${net_dir}/hosts
  
  # create config file
  touch ${net_dir}/tinc.conf
  touch ${net_dir}/tinc-up
  touch ${net_dir}/tinc-down

  # set the permission
  chmod +x ${net_dir}/tinc-*

  echo "Name = $node" >> ${net_dir}/tinc.conf
  echo "ConnectTo = ac"   >> ${net_dir}/tinc.conf
  
  # generate host file
  tincd -n ${NETNAME} -K

  # set subset for this host
  sed -i "1s/^/Subnet = ${ip_addr}\/32\n\n/" ${net_dir}/hosts/${node}

  # upload encrypt file to server
  local hostfile=$( cat ${net_dir}/hosts/${node} )

  # exchange hostfile with cellhub, succed will return 0
  # HTTP error 404 will return 8
  wget -P ${net_dir}/hosts -O ac --post-data="netname=${NETNAME}&node=${node}&hostfile=${hostfile}" http://${CELLHUB}/cell/hosts

  if [ $? != 0 ]; then
    echo "Exchange host file failed, maybe can try it manually ?"
  else
    # set hook script
    echo "#!/bin/sh" >> ${net_dir}/tinc-up
    echo "ip link set \$INTERFACE up" >> ${net_dir}/tinc-up
    echo "ip addr add ${ip_addr}/32 dev \$INTERFACE" >> ${net_dir}/tinc-up
    echo "ip route add ${net_addr} dev \$INTERFACE"  >> ${net_dir}/tinc-up

    echo "#!/bin/sh" >> ${net_dir}/tinc-down
    echo "ip route del ${net_addr} dev \$INTERFACE"  >> ${net_dir}/tinc-down
    echo "ip addr del ${ip_addr}/32 dev \$INTERFACE" >> ${net_dir}/tinc-down
    echo "ip link set \$INTERFACE down" >> ${net_dir}/tinc-down

    # set rid ==> the value of node
    uci set system.@system[0].node=${node}
    uci commit system

    # make it auto start.
    > /etc/config/tinc

    uci set tinc.${NETNAME}=tinc-net
    uci set tinc.${NETNAME}.enabled=1
    uci set tinc.${NETNAME}.Name=${node}
    # TODO: remove debug later
    uci set tinc.${NETNAME}.logfile=/tmp/log/tinc.${NETNAME}.log
    uci set tinc.${NETNAME}.debug=3
    #
    uci commit
  fi
}

# config dropbear
set_dropbear() {
  echo -e "\n>> Set dropbear"

  cp ./config/authorized_keys /etc/dropbear/

  # chmod
  chmod 700 /etc/dropbear
  chmod 600 /etc/dropbear/authorized_keys

  # change default port
  uci set dropbear.@dropbear[0].Port=2018

  # disable username login
  uci set dropbear.@dropbear[0].PasswordAuth=off
  uci set dropbear.@dropbear[0].RootPasswordAuth=off

  uci commit dropbear
  /etc/init.d/dropbear enable

  # config firewall to allow wan access this router by ssh
  uci add firewall rule
  uci set firewall.@rule[-1].src=wan
  uci set firewall.@rule[-1].target=ACCEPT
  uci set firewall.@rule[-1].proto=tcp
  uci set firewall.@rule[-1].dest_port=2018
  uci commit firewall

  echo "ok."
}

set_hostname(){

  while [ -z $HOSTNAME ]
  do
    read -p $'\n>> 设置主机名称 : ' HOSTNAME
    if [ -z $HOSTNAME ]; then
      echo >&2 "主机名称不能为空"
    fi
  done

  uci set system.@system[0].hostname=${HOSTNAME}
  uci commit system
}

set_station() {

  cp ./auto/station /etc/init.d/
  touch /tmp/log/station.log

  chmod 755 ./scripts/station.lua
  chmod 755 /etc/init.d/station

  /etc/init.d/station enable
  /etc/init.d/station enabled && echo "Set Station OK." 
}

auto_reboot(){
  # let router auto reboot
  # check if config file exist
  if ! [ -e /etc/crontabs/root ]; then
    touch /etc/crontabs/root
  fi

  # check if task exist.
  cat /etc/crontabs/root | grep reboot
  if [ $? != 0 ]; then
    # https://wiki.openwrt.org/doc/howto/cron
    #
    # Reboot at 4:30am every day
    # Note: To avoid infinite reboot loop, wait 70 seconds
    # and touch a file in /etc so clock will be set
    # properly to 4:31 on reboot before cron starts.
    # 30 4 * * * sleep 70 && touch /etc/banner && reboot
    echo "30 4 * * * sleep 70 && touch /etc/banner && reboot" >> /etc/crontabs/root
  fi

  # enable crontab
  /etc/init.d/cron enable
}

regist() {
  # let's set
  local res_msg=''

  #####################################
  #
  # Start Regisit this device
  #
  #####################################
  local mac
  while [ ${#mac} -ne 17 ]
  do
    read -p $'\n>> 路由器 MAC 地址: ' mac
    if [ ${#mac} -ne 17 ]; then
      echo >&2 "路由器 MAC 地址长度必须为 17 位!"
    fi
  done

  # netname
  while [ -z $NETNAME ]
  do
    read -p $'\n>> 输入VPN名称 : ' NETNAME
    if [ -z $NETNAME ]; then
      echo >&2 "VPN名称不能为空"
    fi
  done

  set_hostname
  
  echo -e "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

  local username=''
  read -p '>>[Sign in] Your CELLHUB username: ' username

  local password=''
  read -p '>>[Sign in] Your CELLHUB password: ' password
  
  echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"

  echo    "Process..."

  res_msg=$( wget -qO- --post-data="netname=${NETNAME}&mac=${mac}&hostname=${HOSTNAME}&username=${username}&password=${password}" http://${CELLHUB}/cell/reg )

  local is_ok=0

  case ${res_msg} in 
    *false*) is_ok=1 ;;
    *)  is_ok=0 ;;
  esac

  if [ $is_ok -eq 1 ]; then
    echo "Failed: " $res_msg
  else
    echo "Succed: " $res_msg

    set_timezone
    set_version
    set_cellhub
    
    set_tinc ${res_msg}
    set_dropbear
    set_station
    auto_reboot
    reboot
  fi
}

env_check() {
  local pkg_name=$1
  opkg list-installed | grep -q $pkg_name

  # not install
  if [ $? -ne 0 ]; then
    echo "Error: $pkg_name not installed"
    return 1
  else
    return 0
  fi
}

# let's rock....

echo "
==============================================================================
                          Beellion Configuration
                          - Author:     hexcola
                          - Version:    0.1.0

                                   \     /
                                \   o ^ o   /
                                 \ (     ) /
                      ____________(%%%%%%%)____________
                     (     /   /  )%%%%%%%(  \   \     )
                     (___/___/__/     $     \__\___\___)
                        (     /  /(%%%%%%%)\  \     )
                         (__/___/ (%%%%%%%) \___\__)
                                ./(       )\.
                              ./   (%%%%%)   \.
                                    (%%%)
                                      !
=============================================================================="

not_installed_pkg_num=0
# check the requirements
echo "Running environment check."

env_check "tinc"
not_installed_pkg_num=$(( $not_installed_pkg_num + $? ))

env_check "dropbear"
not_installed_pkg_num=$(( $not_installed_pkg_num + $? ))

if [ $not_installed_pkg_num -eq 0 ]; then
  regist
else
  echo "There are $not_installed_pkg_num package not installed, maybe you should try ./install.sh to install"
fi