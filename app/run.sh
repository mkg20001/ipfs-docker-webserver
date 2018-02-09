#!/bin/bash

set -e

die() {
  echo "$@" 2>&1
  exit 2
}

# Basic Bootstrap stuff

[ -z "$IPNS_URL" ] && [ -z "$IPFS_URL" ] && [ -z "$PASSTHROUGH" ] && die "Variable \$IPNS_URL is empty. Set it to your IPNS or DNS domain.
Alternativly set \$IPFS_URL to an arbitrary IPFS url or set \$PASSTHROUGH=1"

[ ! -z "$IPNS_URL" ] && [ ! -z "$IPFS_URL" ] && die "\$IPFS_URL and \$IPNS_URL cannot be set at the same time."

[ ! -z "$IPNS_URL" ] && ipfs="/ipns/$IPNS_URL"
[ ! -z "$IPFS_URL" ] && ipfs="$IPFS_URL"

[ ! -z "$PASSTHROUGH" ] && ipfs=""

if ! echo "$ipfs" | grep "^/" > /dev/null; then
  ipfs="/$ipfs"
fi

if ! echo "$ipfs" | grep "/$" > /dev/null; then
  ipfs="$ipfs/"
fi

if [ "$ipfs" == "/" ]; then
  sed "s|Rewrite|# Rewrite|g" -i /etc/apache2/sites-available/000-default.conf
fi

# Start apache2

sed "s|\$IPFS|$ipfs|g" -i /etc/apache2/sites-available/000-default.conf
sed "s|\$BASE|$(basename $ipfs)|g" -i /etc/apache2/sites-available/000-default.conf

tail -f /var/log/apache2/access.log -n 0 &
tail -f /var/log/apache2/error.log -n 0 &
service apache2 restart
trap "service apache2 stop" SIGINT SIGTERM

# Init and start ipfs

if [ -e /root/.ipfs/blocks ]; then
  echo "(repo exists)"
else
  ipfs init --profile=server
fi

echo "Hosting $ipfs"

ipfs daemon --migrate &
wait
