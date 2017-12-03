#!/bin/bash -l

set -e

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)

build::user::create $USER


log::m-info "Installing essentials ..."
apt-get update -qq
apt-get install -yqq \
    bash-completion \
	ca-certificates \
	curl


tmpd=$(mktemp -d)
pushd $tmpd
	apt-get update -qq
	curl -sLO https://github.com/telephoneorg/kazoo-builder/releases/download/v$KAZOO_VERSION/kazoo_${KAZOO_VERSION}.deb
    dpkg -x kazoo_*.deb .

    mv etc/bash_completion.d/sup.bash /etc/bash_completion.d
    mv opt/kazoo/bin/{nodetool,install_upgrade.escript} /usr/bin
    mv usr/bin/sup /usr/bin
    popd && rm -rf $tmpd && unset tmpd


log::m-info "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
