#!/bin/bash

set -e

die() {
  echo "$@" 2>&1
  exit 2
}

[ -z "$IPNS_URL" ] && die "Variable \$IPNS_URL is empty. Set it to your IPNS or DNS domain."

if [ -e /root/.ipfs/blocks ]; then
  echo "(repo exists)"
else
  ipfs init
  #prevent ipfs from dialing internal addresses
  sed 's|"AddrFilters": null,|"AddrFilters": ["/ip4/10.0.0.0/ipcidr/8","/ip4/100.64.0.0/ipcidr/10","/ip4/169.254.0.0/ipcidr/16","/ip4/172.16.0.0/ipcidr/12","/ip4/192.0.0.0/ipcidr/24","/ip4/192.0.0.0/ipcidr/29","/ip4/192.0.0.8/ipcidr/32","/ip4/192.0.0.170/ipcidr/32","/ip4/192.0.0.171/ipcidr/32","/ip4/192.0.2.0/ipcidr/24","/ip4/192.168.0.0/ipcidr/16","/ip4/198.18.0.0/ipcidr/15","/ip4/198.51.100.0/ipcidr/24","/ip4/203.0.113.0/ipcidr/24","/ip4/240.0.0.0/ipcidr/4"],|g' -i /root/.ipfs/config
fi

on_exit() {
  echo "Exiting..."
  kill -s SIGTERM $IPFSPID
  while [ -e /proc/$IPFSPID ]; do
    sleep .1s
    echo -n .
  done
  echo
  echo "[ipfs] stopped"
  service apache2 stop
  echo "[apache2] stopped"
}

ipns="$IPNS_URL"

sed "s|\$IPNS|$ipns|g" -i /etc/apache2/sites-available/000-default.conf

echo "[HOSTING] /ipns/$ipns/"

service apache2 restart &
ipfs daemon &
IPFSPID=$!
tail --pid=$IPFSPID -f /var/log/apache2/access.log -n 0 &
tail --pid=$IPFSPID -f /var/log/apache2/error.log -n 0 &
trap on_exit SIGINT SIGTERM
sleep infinity
