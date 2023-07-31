#!/usr/bin/env bash

#ONLY UBUNTU SERVER

current_os=$(awk -F= '/PRETTY_NAME/ {print $2}' /etc/os-release)
current_type_os=$(echo $current_os | cut -d ' ' -f 1)
current_version_os=$(echo $current_os | awk '{print $2}' | cut -d '.' -f 1,2)

zabbix_url="https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu${current_version_os}_all.deb"
wget $zabbix_url
zabbix_pkg="zabbix-release_6.4-1+ubuntu${current_version_os}_all.deb"
dpkg -i $zabbix_pkg
apt update -y

apt install -y zabbix-agent

zabbix_server_ip=$(grep "ZABBIX-SERVER_IP" | awk -F"=" '{print $2}')

sed -i "s/^Server=127\.0\.0\.1$/Server=$zabbix_server_ip/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/^ServerActive=127\.0\.0\.1$/Server=$zabbix_server_ip/g" /etc/zabbix/zabbix_agentd.conf

systemctl enable zabbix-agent
systemctl restart zabbix-agent

rm -rf $zabbix_pkg