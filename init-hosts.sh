#!/usr/bin/env bash

set -x

CONTAINER_IP=$(grep "`hostname`" /etc/hosts|awk '{print $1}')

## This do not work wel..
#CONTAINER_IP=$(hostname -I)

CONTIANER_OUTBAND_IP=$( ip route get 8.8.8.8 | awk 'NR==1 {print $NF}')

cp -v /etc/hosts /etc/hosts.backup
cp -v /srv/etc/hosts /srv/etc/hosts.current

safe_pattern=$(printf '%s\n' "${CONTIANER_OUTBAND_IP}" | sed 's/[[\.*^$/]/\\&/g')

sed -i -e "s|^lc-host-proxybind|${safe_pattern}|g" /srv/etc/hosts.current

sed -i -e "s|lc-host-proxybind|${safe_pattern}|g" /usr/local/nginx/vhosts-enabled/*.conf
#sed -i -e "s|listen lancache-[a-z0-9A-Z -]\+default;|listen ${safe_pattern};|g" /usr/local/nginx/vhosts-enabled/*.conf

sed -i -e "s|listen lancache-[a-z0-9A-Z -]\+default;|listen 80;|g" /usr/local/nginx/vhosts-enabled/*.conf

sed -i -e "s| _;|;\n###SERVERNAME###\n|g" /usr/local/nginx/vhosts-enabled/*.conf

mkdir -p /usr/local/nginx/vhosts-domains/

for i in $(ls /usr/local/nginx/vhosts-enabled/*.conf )
do
	echo "$i"
	echo `basename $i`
	safe_pattern=$(printf '\tinclude /usr/local/nginx/vhosts-domains/%s;\n' "$(basename $i)" |sed 's/[[\.*^$/]/\\&/g')
	sed -i -e "s|^###SERVERNAME###|${safe_pattern}|g" $i
	touch "/usr/local/nginx/vhosts-domains/$(basename $i)"
done

mkdir /usr/local/nginx/vhosts-avaliable/ && \
	mv /usr/local/nginx/vhosts-enabled/*.conf /usr/local/nginx/vhosts-avaliable/ && \
	cd /usr/local/nginx/vhosts-enabled/ && ln -s ../vhosts-avaliable/lancache-microsoft.conf

safe_pattern=$(printf '%s\n' "${CONTAINER_IP}" | sed 's/[[\.*^$/]/\\&/g')

sed -i -e "s|^lc-host-[a-z0-9A-Z\-]\+|${safe_pattern}|g" /srv/etc/hosts.current

cat /etc/hosts.backup /srv/etc/hosts.current > /etc/hosts

cat /etc/hosts

find /srv/lancache/logs/

/srv/bin/gen-vhosts-domains-conf.rb

set +x

