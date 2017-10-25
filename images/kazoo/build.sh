#!/bin/bash -l

set -e

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)

build::user::create $USER


log::m-info "Installing essentials ..."
apt-get update -qq
apt-get install -yqq \
	ca-certificates \
	curl \
	jq


KAZOO_RELEASE_DATA=$(curl -sSL https://api.github.com/repos/telephoneorg/kazoo-builder/releases/latest)
KAZOO_RELEASE_TAG=$(jq -r '.tag_name' <(echo $KAZOO_RELEASE_DATA))
KAZOO_RELEASE_DATE=$(jq -r '.published_at' <(echo $KAZOO_RELEASE_DATA))
KAZOO_RELEASE_DOWNLOAD_URL=$(jq -r '.assets[].browser_download_url' <(echo $KAZOO_RELEASE_DATA))

log::m-info "Downloading $APP Release ..."
echo -e "  branch: 	  $KAZOO_RELEASE_TAG
  published:  $KAZOO_RELEASE_DATE
  from: 	  $KAZOO_RELEASE_DOWNLOAD_URL
"

pushd /opt
	curl -sLO $KAZOO_RELEASE_DOWNLOAD_URL
	tar xzvf kazoo.*.tar.gz --strip-components=1
	rm -f kazoo.*.tar.gz
	popd


log::m-info "Removing jq ..."
apt-get purge -y --auto-remove jq


log::m-info "Installing $APP dependencies ..."
apt-get install -yqq \
	expat \
	htmldoc \
	libexpat1-dev \
	libssl1.0.2 \
	libssl-dev \
	libncurses5-dev \
	libxslt-dev \
	openssl \
    zlib1g-dev \
	iputils-ping


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
