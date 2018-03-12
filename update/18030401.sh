#!/bin/sh

WORKSPACE=/root/cell
CELLV='18030401'

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

set_station(){

  # stop station handler
  /etc/init.d/station stop

  # disable station
  /etc/init.d/station disable

  # delete relate scripts
  rm /etc/init.d/station
  rm /root/cell/scripts/station.lua

  # delete logs
  rm /tmp/log/station.log

  # update version
  set_version
  
  echo "Remove Station handler OK." 
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
  set_station
  echo "Update finished."
fi
