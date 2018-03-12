#!/bin/sh

opkg update

PkgFile=./package

echo -e "\nStart install packages.\n"

while read line
do
  # check if $line package installed
  opkg list-installed | grep -q $line
  # not installed then we install it!
  if [ $? -ne 0 ]; then
    opkg install $line
  fi
done < "$PkgFile"

# check again if not installed we should recommand user do it manually
while read line
do
  # check if $line package installed
  opkg list-installed | grep -q $line
  # not installed then we install it!
  if [ $? -ne 0 ]; then
    echo "Package: [$line] not installed, you should install it manually!!!" 
  else
    echo "Package: [$line] install successfully!"
  fi
done < "$PkgFile"