#!/bin/bash -l

set -e

KAZOO_RELEASE_VERSION=${KAZOO_VERSION}-${KAZOO_BUILD_NUMBER}

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)

build::user::create $USER

apt-get -q update


log::m-info "Installing essentials ..."
apt-get install -qq -y \
	ca-certificates \
	curl


log::m-info "Downloading $APP build: $KAZOO_RELEASE_VERSION ..."
pushd /opt
    curl -sSL \
		https://github.com/sip-li/kazoo-builder/releases/download/${KAZOO_RELEASE_VERSION}/kazoo.tar.gz \
        | tar xzf - --strip-components=1 -C .
	popd


log::m-info "Installing $APP dependencies ..."
apt-get install -qq -y \
	expat \
	htmldoc \
	libexpat1-dev \
	libssl-dev \
	libncurses5-dev \
	libxslt-dev \
    zlib1g-dev


log::m-info "Removing unnecessary packages ..."
apt-get purge -y --auto-remove ca-certificates


log::m-info "linking kazoo-configs ..."
mkdir -p /etc/kazoo
ln -s ~/etc/kazoo/core /etc/kazoo/core


log::m-info "linking sup ..."
ln -s ~/bin/sup /usr/bin/sup


log::m-info "linking bash_completion for sup ..."
ln -s  ~/sup.bash /etc/bash_completion.d/sup.bash


log::m-info "linking monster-ui to /var/www/html/monster-ui ..."
mkdir -p /var/www/html
ln -s ~/monster-ui $_/monster-ui


log::m-info "Adding app init to entrypoint.d ..."
tee /etc/entrypoint.d/50-${APP}-init <<'EOF'
# write the erlang cookie
erlang-cookie write

# ref: http://erlang.org/doc/apps/erts/crash_dump.html
erlang::set-erl-dump
EOF


log::m-info "Adding erts directory to paths.d ..."
tee /etc/paths.d/20-${APP} <<EOF
~/erts-$(cat ~/releases/RELEASES | head -1 | cut -d',' -f4 | xargs)/bin
EOF


log::m-info "Adding ${APP}-env to environment.d ..."
tee /etc/environment.d/40-${APP}-env <<EOF
ERTS_DIR=~/erts-$(cat ~/releases/RELEASES | head -1 | cut -d',' -f4 | xargs)
KAZOO_RELEASE=$(cat ~/releases/RELEASES | head -1 | cut -d',' -f3 | xargs)
ERTS_VERSION=$(cat ~/releases/RELEASES | head -1 | cut -d',' -f4 | xargs)
LD_LIBRARY_PATH=$HOME/erts-$(cat ~/releases/RELEASES | head -1 | cut -d',' -f4 | xargs)/lib:\$LD_LIBRARY_PATH
ERTS_LIB_DIR=$HOME/lib
EOF


log::m-info "Adding /etc/kazoo to fixattrs.d ..."
tee /etc/fixattrs.d/20-${APP}-perms <<EOF
/opt/kazoo/etc true $USER:$USER 0644 0755
EOF


log::m-info "Creating Directories ..."
mkdir -p /var/run/kazoo


log::m-info "Setting Ownership & Permissions ..."
chown -R $USER:$USER ~ /var/run/kazoo


log::m-info "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
