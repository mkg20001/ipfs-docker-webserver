#!/bin/bash

set -e

die() {
  echo "$@" 2>&1
  exit 2
}

#Basic Bootstrap stuff

[ -z "$IPNS_URL" ] && [ -z "$IPFS_URL" ] && die "Variable \$IPNS_URL is empty. Set it to your IPNS or DNS domain.
Alternativly set \$IPFS_URL to an arbitrary url"

[ ! -z "$IPNS_URL" ] && [ ! -z "$IPFS_URL" ] && die "\$IPFS_URL and \$IPNS_URL cannot be set at the same time."

[ ! -z "$IPNS_URL" ] && ipfs="/ipns/$IPNS_URL"
[ ! -z "$IPFS_URL" ] && ipfs="$IPFS_URL"

if ! echo "$ipfs" | grep "^/" > /dev/null; then
  ipfs="/$ipfs"
fi

if ! echo "$ipfs" | grep "/$" > /dev/null; then
  ipfs="$ipfs/"
fi

#Start apache2

sed "s|\$IPFS|$ipfs|g" -i /etc/apache2/sites-available/000-default.conf
sed "s|\$BASE|$(basename $ipfs)|g" -i /etc/apache2/sites-available/000-default.conf

tail -f /var/log/apache2/access.log -n 0 &
tail -f /var/log/apache2/error.log -n 0 &
service apache2 restart
trap "service apache2 stop" SIGINT SIGTERM

#Init and start ipfs

if [ -e /root/.ipfs/blocks ]; then
  echo "(repo exists)"
else
  ipfs init
  #prevent ipfs from dialing internal addresses
  sed 's|"AddrFilters": null,|"AddrFilters": ["/ip4/10.0.0.0/ipcidr/8","/ip4/100.64.0.0/ipcidr/10","/ip4/169.254.0.0/ipcidr/16","/ip4/172.16.0.0/ipcidr/12","/ip4/192.0.0.0/ipcidr/24","/ip4/192.0.0.0/ipcidr/29","/ip4/192.0.0.8/ipcidr/32","/ip4/192.0.0.170/ipcidr/32","/ip4/192.0.0.171/ipcidr/32","/ip4/192.0.2.0/ipcidr/24","/ip4/192.168.0.0/ipcidr/16","/ip4/198.18.0.0/ipcidr/15","/ip4/198.51.100.0/ipcidr/24","/ip4/203.0.113.0/ipcidr/24","/ip4/240.0.0.0/ipcidr/4"],|g' -i /root/.ipfs/config
fi

echo "[HOSTING] $ipfs"

ipfs daemon --migrate &
wait
