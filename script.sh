#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/src/env.sh

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 1
fi

file_name="$DIR/config.txt"

if [ ! -f "$file_name" ]; then
    echo "$file_name not found."
	exit 1
fi

apt update 
apt upgrade -y

chmod -R 777 $DIR

# Getting user login and pass from config.txt

new_user=$(grep -m 1 NEW_USER ./config.txt | awk -F"=" '{print $2}')
new_pass=$(grep -m 1 NEW_PASS ./config.txt | awk -F"=" '{print $2}')

# Adding new user 

echo "$new_user:$new_pass" | chpasswd

echo
echo "Configuring routing..."
$DIR/src/sysctl.sh

echo
echo "Installing strongSwan and xl2tp server..."
$DIR/src/ipsec.sh

echo
echo "Starting strongSwan and xl2tp..."
systemctl restart xl2tpd
ipsec restart

echo
chap_secrets_file="/etc/ppp/chap-secrets"
common_password=$(grep -m 1 VPN_PASS ./config.txt | awk -F"=" '{print $2}')
echo "Adding user to chap-secrets files."
echo -e "PX_ROUTER\t*\t$common_password\t*" >> "$chap_secrets_file"
echo -e "PX_ROUTER\t*\t$common_password\t*" >> "$chap_secrets_file"
echo -e "ST_ROUTER\t*\t$common_password\t*" >> "$chap_secrets_file"
echo -e "BS_ROUTER\t*\t$common_password\t*" >> "$chap_secrets_file"
echo -e "LV_ROUTER1\t*\t$common_password\t*" >> "$chap_secrets_file"
echo -e "LV_ROUTER2\t*\t$common_password\t*" >> "$chap_secrets_file"
echo -e "KV_ROUTER\t*\t$common_password\t*" >> "$chap_secrets_file"

echo
echo
echo "Installation script has been completed!"
echo





