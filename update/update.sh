#!/bin/sh

# UPDATE NOTE:
# 1. install & config nodogsplash
# 2. use local opkg mirror

WORKSPACE=/root/cell
CELLV='2018022301'

set_NETGEAR_repo() {
  # test if backup file exist.
  # https://github.com/hexcola/note/issues/54

  local backup_file=/etc/opkg/distfeeds.conf.backup
  if [ -e $backup_file ]; then
    # empty default config
    > /etc/opkg/distfeeds.conf
  else
    mv /etc/opkg/distfeeds.conf /etc/opkg/distfeeds.conf.backup
    touch /etc/opkg/distfeeds.conf
  fi

  echo "src/gz reboot_telephony http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/packages/mips_24kc/telephony" >> /etc/opkg/distfeeds.conf
  echo "src/gz reboot_routing http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/packages/mips_24kc/routing" >> /etc/opkg/distfeeds.conf
  echo "src/gz reboot_packages http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/packages/mips_24kc/packages" >> /etc/opkg/distfeeds.conf
  echo "src/gz reboot_luci http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/packages/mips_24kc/luci" >> /etc/opkg/distfeeds.conf
  echo "src/gz reboot_base http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/packages/mips_24kc/base" >> /etc/opkg/distfeeds.conf
  echo "src/gz reboot_core http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/targets/ar71xx/nand/packages" >> /etc/opkg/distfeeds.conf

}

set_Xiaomi_repo() {
  # test if backup file exist.
  # https://github.com/hexcola/note/issues/54

  local backup_file=/etc/opkg/distfeeds.conf.backup
  if [ -e $backup_file ]; then
    # empty default config
    > /etc/opkg/distfeeds.conf
  else
    mv /etc/opkg/distfeeds.conf /etc/opkg/distfeeds.conf.backup
    touch /etc/opkg/distfeeds.conf
  fi

  echo "src/gz reboot_telephony http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/packages/mipsel_24kc/telephony" >> /etc/opkg/distfeeds.conf
  echo "src/gz reboot_routing http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/packages/mipsel_24kc/routing" >> /etc/opkg/distfeeds.conf
  echo "src/gz reboot_packages http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/packages/mipsel_24kc/packages" >> /etc/opkg/distfeeds.conf
  echo "src/gz reboot_luci http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/packages/mipsel_24kc/luci" >> /etc/opkg/distfeeds.conf
  echo "src/gz reboot_base http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/packages/mipsel_24kc/base" >> /etc/opkg/distfeeds.conf
  echo "src/gz reboot_core http://ianki.cn:1338/downloads.lede-project.org/releases/17.01.4/targets/ramips/mt7620/packages" >> /etc/opkg/distfeeds.conf

}

set_opkg() {
  local machine=$(cat /proc/cpuinfo | grep machine | awk '{print $3}')
  case ${machine} in 
    NETGEAR) set_NETGEAR_repo ;;
    Xiaomi) set_Xiaomi_repo ;;
  esac
}

set_nodogsplash() {

  # empty /etc/config/nodogsplash file
  uci set nodogsplash.@nodogsplash[0].enabled=1
  uci add_list nodogsplash.@nodogsplash[0].authenticated_users='allow tcp port 1338'
  uci add_list nodogsplash.@nodogsplash[0].authenticated_users='allow tcp port 2018'
  uci add_list nodogsplash.@nodogsplash[0].authenticated_users='allow tcp port 8118'

  uci add_list nodogsplash.@nodogsplash[0].preauthenticated_users='allow tcp port 443'
  uci add_list nodogsplash.@nodogsplash[0].preauthenticated_users='allow tcp port 1338'
  uci add_list nodogsplash.@nodogsplash[0].preauthenticated_users='allow tcp port 2018'
  uci add_list nodogsplash.@nodogsplash[0].preauthenticated_users='allow tcp port 8118'

  uci add_list nodogsplash.@nodogsplash[0].users_to_router='allow tcp port 1338'
  uci add_list nodogsplash.@nodogsplash[0].users_to_router='allow tcp port 2018'
  uci add_list nodogsplash.@nodogsplash[0].users_to_router='allow tcp port 8118'

  uci commit nodogsplash

  # edit the /etc/nodogsplash/htdocs/splash.html
  rm /etc/nodogsplash/htdocs/splash.html
  cp ${WORKSPACE}/upgrade/2018022301/splash.html /etc/nodogsplash/htdocs/

  # start nodogsplash
  /etc/init.d/nodogsplash start
  echo "ok."
}

check_version() {                                            
  # if version already matched, we don't do the code after.  
  curr_v=$(uci get system.@system[0].cellv)                  
                                                             
  echo 'current version: ' $curr_v                           
  echo 'package version: ' $CELLV                            
                                                             
  if [ ${curr_v} == ${CELLV} ]; then                         
    # this package is installed                   
    return 0                                                 
  else
    return 1
  fi
} 

# set the version number
set_version() {
  uci set system.@system[0].cellv=${CELLV}
  uci commit system
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

echo "
==============================================================================
                            Beellion Update
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

# check if current update installed or not.
check_version

if [ $? -eq 0 ]; then
  echo "Current update installed."
else
  echo "Set Opkg repository."
  set_opkg

  # install and config nodogsplash
  not_installed_pkg_num=0
  # check the requirements
  echo "Running environment check."

  env_check "nodogsplash"
  not_installed_pkg_num=$(( $not_installed_pkg_num + $? ))

  if [ $not_installed_pkg_num -eq 0 ]; then
    set_nodogsplash
    set_version
  else
    echo "There are $not_installed_pkg_num package not installed, maybe you should try ./install.sh to install"
    echo "Or you can use these command: "
    echo "opkg update"
    echo "opkg install nodogsplash"
  fi

  echo "Update finished."
fi
