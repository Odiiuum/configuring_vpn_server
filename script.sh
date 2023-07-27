#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/src/env.sh

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 1
fi

apt update 
apt upgrade -y

$SCRIPT_DIR=$(pwd)

chmod -R 777 $SCRIPT_DIR/start_vpn

# Getting user login and pass from requirements.txt

new_user=$(grep -m 1 NEW_USER ./requirements.txt | awk -F"=" '{print $2}')
new_pass=$(grep -m 1 NEW_PASS ./requirements.txt | awk -F"=" '{print $2}')

# Adding new user 

useradd -m -s /bin/bash $new_user
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
echo
echo "Installation script has been completed!"



