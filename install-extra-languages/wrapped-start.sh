#!/bin/sh

# script which wraps the normal start.sh script of the judgehost to that
# we before starting the judgehost we can install extra languages in the chroot environment of 
# the judgehost using the 'install-languages' script

# following line copied from /scripts/start.sh which is needed to get network running right in chroot
cp /etc/resolv.conf /chroot/domjudge/etc/resolv.conf
# run script to install extra languages in chroot
/opt/domjudge/judgehost/bin/dj_run_chroot /bin/install-languages
# start normal judgehost start script
exec /scripts/start.sh
