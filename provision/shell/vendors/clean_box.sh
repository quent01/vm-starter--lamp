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


# Delete bash histroy and exit
cat /dev/null > ~/.bash_history && history -c && exit