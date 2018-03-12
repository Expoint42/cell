#!/bin/sh
# Config file: /etc/config/wireless

idx=$1

set_wifi() {
  # enable wifi defice
  uci set wireless.@wifi-device[$idx].disabled=0

  if [ $? != 0 ]; then
    echo "WiFi device not exist. try another one."
  else
    while [ -z $ssid ]
    do
      read -p $'\n>> Set WiFi SSID (default: 无线郑州): ' ssid
      ssid=${ssid:-无线郑州}
    done
    # echo "wifi ssid='$ssid'"
    uci set wireless.@wifi-iface[$idx].ssid=${ssid}
    uci set wireless.@wifi-iface[$idx].encryption='psk-mixed'

    password=''
    while [ ${#password} -lt 8 ]
    do
      read -p $'\n>>Set WiFi Password: ' password
      if [ ${#password} -lt 8 ]; then
        echo "The length of password at least 8 bits!"
      fi
    done
    echo $password
    uci set wireless.@wifi-iface[$idx].key=${password}
    echo 'ok.'

    uci commit wireless
  fi
}


if [ "$idx" == "" ]; then
  echo "You must specify the device, e.g. 0 or 1"
else                                          
   set_wifi                                   
fi                                            
