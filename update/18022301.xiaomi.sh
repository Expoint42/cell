#!/bin/sh

# UPDATE NOTE:
# 1. install & config nodogsplash
# 2. use local opkg mirror

WORKSPACE=/root/cell
CELLV='2018022301'

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

set_opkg() {
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
  
  opkg update
}

set_wifidog() {
    # install package
    opkg install ./xiaomi-mini-v1/fping_4.0-2_mipsel_24kc.ipk
    opkg install ./xiaomi-mini-v1/libevent2_2.1.8-1_mipsel_24kc.ipk
    opkg install ./xiaomi-mini-v1/libevent2-openssl_2.1.8-1_mipsel_24kc.ipk
    opkg install ./xiaomi-mini-v1/apfree_wifidog_2.10.1437-1_mipsel_24kc.ipk

    # config
    uci set wifidog.@wifidog[0].auth_server_hostname="ianki.cn"
    uci set wifidog.@wifidog[0].auth_server_port=1338
    uci set wifidog.@wifidog[0].client_timeout=1440
    uci set wifidog.@wifidog[0].wired_passed=1
    uci delete wifidog.@mqtt[0]
    uci commit wifidog

    /etc/init.d/wifidog stop
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
  set_wifidog
  set_version
  echo "Update finished."
fi
