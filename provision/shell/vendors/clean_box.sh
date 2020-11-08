#!/bin/bash
#
# clean.sh
#

# "Zero it out" (make it small as possible)
sudo dd if=/dev/zero of=/EMPTY bs=1M

sudo rm -f /EMPTY


# Clear APT cache (make it smaller)
sudo apt-get autoremove

sudo apt-get clean


# Delete bash history and exit
cat /dev/null > ~/.bash_history && history -c

echo "---------------------------------"
echo "The box was cleaned"
echo "Exit the box and lauch : "
echo "---------------------------------"
echo "---> vagrant halt"
echo "---> vagrant package --output <name_of_box>.box"
echo "---> vagrant cloud publish <org_name>/<box_name> <version> virtualbox <name_of_box>.box"
echo "---> Once the box as been publish connect on https://app.vagrantup.com/ and release the version"
echo "---------------------------------"