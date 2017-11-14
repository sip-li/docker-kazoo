#!/bin/bash -l

set -e

KAZOO_SHORT_VERSION=${KAZOO_VERSION%.*}

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)

build::user::create $USER


log::m-info "Installing essentials ..."
apt-get update -qq
apt-get install -yqq \
	ca-certificates \
	curl


tmpd=$(mktemp -d)
pushd $tmpd
	apt-get update -qq
	log::m-info "Kazoo & Kazoo Configs"
	log::m-info "  Downloading ..."
	curl -sLO https://github.com/telephoneorg/kazoo-builder/releases/download/v$KAZOO_VERSION/kazoo_${KAZOO_VERSION}.deb
	curl -sLO https://github.com/telephoneorg/kazoo-builder/releases/download/v$KAZOO_VERSION/kazoo-configs_${KAZOO_CONFIGS_VERSION}.deb
	log::m-info "  Installing ..."
	apt install -y ./*.deb
	popd && rm -rf $tmpd && unset tmpd


log::m-info "Adding app init to entrypoint.d ..."
tee /etc/entrypoint.d/50-${APP}-init <<'EOF'
# write the erlang cookie
erlang-cookie write

# ref: http://erlang.org/doc/apps/erts/crash_dump.html
erlang::set-erl-dump

if linux::cap::is-enabled 'sys_resource'; then
    echo "setting ulimits ..."
    set-limits kazoo
else
    linux::cap::show-warning 'sys_resource'
fi

if linux::cap::is-disabled 'sys_nice'; then
    linux::cap::show-warning 'sys_nice'
fi
EOF


log::m-info "Adding erts directory to paths.d ..."
tee /etc/paths.d/20-${APP} <<EOF
~/erts-$(cat ~/releases/RELEASES | head -1 | cut -d',' -f4 | xargs)/bin
~/bin
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
/etc/kazoo true $USER:$USER 0644 0755
/var/run/kazoo true $USER:$USER 0755 0755
/var/www/html/monster-ui true $USER:$USER 0777 0777
/opt/kazoo/media/prompts true $USER:$USER 0777 0777
/config true $USER:$USER 0755 0755
EOF


log::m-info "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
