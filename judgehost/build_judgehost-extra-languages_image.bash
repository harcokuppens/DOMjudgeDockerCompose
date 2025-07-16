#!/bin/bash

DOMJUDGE_VERSION="8.3.1"

# ------------------------------------------------------------------------------
# This script builds a custom domjudge/judgehost image with extra languages.
#
# ❗️ Why do we use a script with `docker run` + `docker commit` instead of a pure Dockerfile?
#
# During a normal `docker build`, the Docker build environment is isolated
# and does not allow privileged operations like `mount` or `chroot`.
# The DOMjudge judgehost setup relies on chrooting into /chroot/domjudge and mounting /proc,
# which is not possible in a normal Dockerfile build step due to security restrictions.
#
# To work around this, we:
#   - Start a temporary, privileged container from the base judgehost image.
#   - Copy the install-languages script into the chroot.
#   - Run commands inside the running container to set up cgroups, fix resolv.conf,
#     and execute the chrooted install script.
#   - Commit the container’s modified state as a new image.
#
# This way, the extra languages are installed *inside the chroot* as needed,
# even though Docker build alone cannot perform the required privileged operations.
# ------------------------------------------------------------------------------

script_dir=$(dirname $0)
script_dir="$(realpath $script_dir)"
cd "${script_dir}" || exit 1

PREFIX="--> "
echo "${PREFIX}starting to create image domjudge/judgehost-extra-languages:${DOMJUDGE_VERSION}"
echo "${PREFIX}creating temporary container mycontainer to install extra languages in chroot environment of judgehost"
docker  run -d  --name mycontainer --privileged domjudge/judgehost:${DOMJUDGE_VERSION} /bin/sh -c "sleep infinity # install rustc and kotlinc in chroot environment" 
# note: sleep infinity ensures nothing happens except your setup steps, and the container remains running
echo "${PREFIX}copying install-languages script to temporary container mycontainer"
docker cp install-extra-languages//install-languages mycontainer:/chroot/domjudge/bin/install-languages
docker exec mycontainer /opt/domjudge/judgehost/bin/create_cgroups 
docker exec mycontainer cp /etc/resolv.conf /chroot/domjudge/etc/resolv.conf
echo "${PREFIX}installing extra languages in chroot environment of judgehost"
docker exec mycontainer /opt/domjudge/judgehost/bin/dj_run_chroot /bin/install-languages
echo "${PREFIX}creating image domjudge/judgehost-extra-languages:${DOMJUDGE_VERSION}"
docker commit --change='CMD ["/scripts/start.sh"]' mycontainer domjudge/judgehost-extra-languages:${DOMJUDGE_VERSION}
echo "${PREFIX}removing temporary container mycontainer"
docker rm -f mycontainer
echo "${PREFIX}finished creating image domjudge/judgehost-extra-languages:${DOMJUDGE_VERSION}"