#!/bin/sh
# 4G Configuration 
# Config file: /etc/config/network

install_pkg() {
  opkg update
  opkg install comgt 
  opkg install kmod-usb-core 
  opkg install kmod-usb2 
  opkg install kmod-usb-serial
  opkg install kmod-usb-serial-wwan
  opkg install kmod-usb-serial-option
  opkg install ppp
  opkg install kmod-ppp
  opkg install luci-proto-3g
}

config() {
  local device
  device="/dev/$1"
  
  echo $device

  # set nework
  uci set network.Modem=interface
  uci set network.Modem.proto="3g"
  uci set network.Modem.device=${device}
  uci set network.Modem.service="umts"
  uci set network.Modem.apn="3gnet"
  
  # set firewall
  uci set firewall.@zone[1].network='Modem'
  
  uci commit
}


set_4g() {
  # Install package
  install_pkg

  echo "Wait. looking for SIM device ..."
  # config
  # list all ttyUSB device
  local usb_devices=$( ls /dev | grep ttyUSB )
  local sim_device=''


  set -- $usb_devices  
  
  while [ -n "$1" ]; do                 
    comgt -d /dev/$1 | grep ready   
                                    
    if [ $? == 0 ]; then
      sim_device=$1
      break
    else
      shift
    fi                           
  done

  if [ sim_device != '' ]; then
    config $sim_device
  else
    echo "No SIM Card found"
  fi
  echo "ok."
}

echo -e "\n>> Set 4G"
echo "+---------------------------------------------------------+"
echo "| Note: Insert SIM card before you power on router!!      |"
echo "+---------------------------------------------------------+"
set_4g