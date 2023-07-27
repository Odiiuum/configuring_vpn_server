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
echo
echo
echo "Starting strongSwan and xl2tp..."
systemctl restart xl2tpd
ipsec restart

echo
echo
echo "Installation script has been completed!"
echo




