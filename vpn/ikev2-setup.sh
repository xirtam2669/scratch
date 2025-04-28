#!/bin/bash
# This script is intended to be run as root
# Usage: ./ikev2-setup.sh <username>
# Example: ./ikev2-setup.sh alex.messham
# This script will install strongswan, configure it for IKEv2, and set up the necessary certificates and prepare the secrets file.

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi
# Check if the username argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

# Check if the system is Ubuntu 24.04 or later
if [ "$(lsb_release -rs)" != "24.04" ]; then
    echo "This script is intended for Ubuntu 24.04 or later. Exiting."
    exit 1
fi

echo -e "\e[1;32m===============================\e[0m"
echo -e "\e[1;34mInstalling strongSwan package...\e[0m"
echo -e "\e[1;32m===============================\e[0m"
# Install strongSwan and necessary plugins
apt update && sudo apt upgrade -y
apt install strongswan libcharon-extra-plugins -y 

#Install certificate
echo -e "\e[1;32m===============================\e[0m"
echo -e "\e[1;34mInstalling Certificate...\e[0m"
echo -e "\e[1;32m===============================\e[0m"

echo "Installing Certificate..."
cp ca-datayard.crt /etc/ipsec.d/cacerts/

#Configuring EAP authentication in secrets file
echo -e "\e[1;32m===============================\e[0m"
echo -e "\e[1;32mPrepping Secrets file at: /etc/ipsec.secrets ...\e[0m"
echo -e "\e[1;32m===============================\e[0m"

echo "$1 : EAP \"<password>\"" >> /etc/ipsec.secrets

#Configuring ipsec

echo "Configuring ipsec..."
echo -e "\e[1;32m===============================\e[0m"
echo -e "\e[1;32mConfiguring IPsec...\e[0m"
echo -e "\e[1;32m===============================\e[0m"

ipsec_conf="config setup
  charondebug=\"ike 1, knl 2, cfg 2\"

conn mmm
  keyexchange=ikev2
  auto=start
  type=tunnel

  right=mmm.datayard.us
  rightid=%any
  rightauth=pubkey
  rightsubnet=10.130.7.0/24, 64.56.102.7/32, 64.56.111.139/32, 64.56.111.152/32, 64.56.111.156/32, 64.56.111.157/32, 72.9.34.246/32

  leftauth=eap-mschapv2
  eap_identity=$1
  leftsourceip=%config"

echo "$ipsec_conf" > /etc/ipsec.conf

#Done
echo -e "\e[1;32m===============================\e[0m"
echo -e "\e[1;34mIpsec configured. Next steps:\e[0m"
echo -e "\e[1;32m===============================\e[0m"
echo -e "\e[1;33m- Make sure to update your /etc/ipsec.secrets with your sys.inf credentials.\e[0m"
echo -e "\e[1;33m- Manually set your default interface in /etc/strongswan.d/charon/resolve.conf.\e[0m"
echo -e "\e[1;33m    - You can find the interface by running: ip addr | grep {right_ip_addr}\e[0m"

