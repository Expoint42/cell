#!/bin/sh
# Set Bandwidth

set_bandwidth() {

  local flag=-1
  local wifi_limit=200
  local pkt_num=180

  while [ $flag -eq -1 ]
  do
    read -p 'WiFi speed limit(default 200kB): ' wifi_limit
    wifi_limit=${wifi_limit:-200}

    case $wifi_limit in
      ''|*[!0-9]*) flag=-1 ;;
      *)
        if [ $wifi_limit -gt 0 ]
        then
          flag=0
          # put the packet/s to kB algorithm here.
          pkt_num=$( expr $wifi_limit \* 256 / 285 + 1 )
        fi
        ;;
    esac
  done
  # TO-DO add to /etc/config/firewall or /etc/firewall.user
  echo "iptables -A forwarding_rule -m limit -d ${LAN_ADDR}/24 --limit ${pkt_num}/sec -j ACCEPT" >> /etc/firewall.user
  echo "iptables -A forwarding_rule -d ${LAN_ADDR}/24 -j DROP" >> /etc/firewall.user
  echo "ok."
}

echo -e "\n>> Set badwidth limitation"
set_bandwidth