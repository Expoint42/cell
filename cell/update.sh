#!/bin/sh

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


# Hack code.
chmod -R +x ./upgrade

./upgrade/2018022301/update.sh




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




# download the list & read line to compare find the version number match to
# current version, if found, the version will be something you need to download
# execute.


# first just download & execute <cellhub>/<version>.sh 
# if not found then need to check the model of this machine, then try to find
# <cellhub>/<version>.<model>.sh & execute, if still not working, report error

