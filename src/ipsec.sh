#!/usr/bin/env bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $DIR/env.sh

eval $PCKTMANAGER update
if [ "$PLATFORM" == "$CENTOSPLATFORM" ]; then
	eval $INSTALLER epel-release
fi
eval $INSTALLER strongswan xl2tpd ppp $CRON_PACKAGE $IPTABLES_PACKAGE procps net-tools

echo
echo "Installing configuration files..."
yes | cp -rf $DIR/options.xl2tpd.dist $PPPCONFIG
yes | cp -rf $DIR/xl2tpd.conf.dist $XL2TPDCONFIG
yes | cp -rf $DIR/ipsec.conf.dist $IPSECCONFIG

sed -i -e "s@PPPCONFIG@$PPPCONFIG@g" $XL2TPDCONFIG
sed -i -e "s@LOCALPREFIX@$LOCALPREFIX@g" $XL2TPDCONFIG

sed -i -e "s@LOCALIPMASK@$LOCALIPMASK@g" $IPSECCONFIG

echo
echo "Configuring iptables firewall..."
$DIR/iptables-setup.sh

echo
echo "Configuring DNS parameters..."
DNS1="8.8.8.8"
DNS2="8.8.4.4"

sed -i -e "/ms-dns/d" $PPPCONFIG

echo "ms-dns $DNS1" >> $PPPCONFIG
echo "ms-dns $DNS2" >> $PPPCONFIG

echo "$PPPCONFIG updated!"

echo
echo "Configuring PSK..."
PSK=$(grep -m 1 PSK $DIR/config.txt | awk -F"=" '{print $2}')

echo -e "\n%any %any : PSK \"$PSK\"" >> $SECRETSFILE

echo "$SECRETSFILE updated!"

echo
echo "Adding cron jobs..."

TMPFILE=$(mktemp crontab.XXXXX)
crontab -l > $TMPFILE

RESTOREPATH=$(which iptables-restore)
RESTORPRESENTS=$(grep iptables-restore $TMPFILE)
if [ $? -ne 0 ]; then
	echo "@reboot $RESTOREPATH <$IPTABLES >/dev/null 2>&1" >> $TMPFILE
fi

SERVERSPRESENTS=$(grep "$CHECKSERVER" $TMPFILE)
if [ $? -ne 0 ]; then
	echo "*/5 * * * * $CHECKSERVER >/dev/null 2>&1" >> $TMPFILE
fi

crontab $TMPFILE > /dev/null
rm $TMPFILE


