#!/bin/sh

CELLV='18030901'

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


update_wifidog() {
  # read $node value from /etc/config/system
  local node=$(uci get system.@system[0].node)

  if [ $? -ne 0 ]; then
    echo "Error: node value not found"
  else
    # set $gateway_id in the /ect/config/wifidog
    uci set wifidog.@wifidog[0].gateway_id=${node}
    uci commit wifidog

    # reload config
    /etc/init.d/wifidog reload

    # update version
    set_version
  fi
}

# check if current update installed or not.
check_version

if [ $? -eq 0 ]; then
  echo "Current update installed."
else
  update_wifidog
  echo "Update finished."
fi