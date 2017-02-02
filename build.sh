#!/bin/bash -l

set -e

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)

build::user::create $USER

apt-get -q update


log::m-info "Installing essentials ..."
apt-get install -qq -y curl ca-certificates


log::m-info "Installing dependencies ..."
apt-get install -qq -y \
	build-essential \
	expat \
	git-core \
	htmldoc \
	libexpat1-dev \
	libssl-dev \
	libncurses5-dev \
	libxslt-dev \
	python \
    unzip \
    wget \
    zip \
    zlib1g-dev


log::m-info "Installing kerl ..."
curl -sSL -o /usr/bin/kerl \
	https://raw.githubusercontent.com/yrashk/kerl/master/kerl
chmod +x /usr/bin/kerl


log::m-info "Installing erlang $ERLANG_VERSION ..."
# export KERL_CONFIGURE_OPTIONS
kerl build $ERLANG_VERSION r${ERLANG_VERSION}
kerl install $_ /usr/lib/erlang
. /usr/lib/erlang/activate


log::m-info "Installing kazoo ..."
cd /tmp
	git clone -b $KAZOO_BRANCH --single-branch --depth 1 https://github.com/2600Hz/kazoo kazoo
	pushd $_
		make
		make build-release
		make sup_completion
		pushd _rel/kazoo
			find -type d -exec mkdir -p ~/\{} \;
	        find -type f -exec mv \{} ~/\{} \;
			popd
		mv sup.bash /etc/bash_completion.d/
		mv core/sup/sup /bin/
		mv {scripts,doc} ~/
		popd && rm -rf $OLDPWD


log::m-info "Installing kazoo-configs ..."
cd /tmp
	git clone -b $KAZOO_CONFIGS_BRANCH --single-branch --depth 1 https://github.com/2600hz/kazoo-configs kazoo-configs
	pushd $_
		find -mindepth 1 -maxdepth 1 -not -name system -not -name core -exec rm -rf {} \;
		#mv system/sbin/{kazoo-applications,kazoo-ecallmgr} /usr/sbin/
		mkdir -p /etc/kazoo/core
		mv core/* $_
		popd && rm -rf $OLDPWD


log::m-info "Installing kazoo-sounds ..."
cd /tmp
	git clone -b $KAZOO_SOUNDS_BRANCH --single-branch --depth 1 https://github.com/2600hz/kazoo-sounds kazoo-sounds
	pushd $_
		mkdir -p ~/media/prompts
		mv kazoo-core/* $_
		popd && rm -rf $OLDPWD


log::m-info "Installing nodejs v$NODE_VERSION ..."
curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt-get install -y nodejs


log::m-info "Installing node packages ..."
npm install -g npm gulp


log::m-info "Installing monster-ui ..."
mkdir -p /var/www/html/monster-ui
cd /tmp
	git clone -b $MONSTER_APPS_BRANCH --single-branch --depth 1 https://github.com/2600hz/monster-ui monster-ui
	pushd $_
		log::m-info "Installing monster-ui apps ..."
		pushd src/apps
			for app in ${MONSTER_APPS//,/ }; do
				git clone -b $MONSTER_APPS_BRANCH --single-branch --depth 1 https://github.com/2600hz/monster-ui-${app} $app
			done
			popd
		npm install
		gulp build-prod
		pushd dist/apps
			git clone -b $MONSTER_APP_APIEXPLORER_BRANCH --single-branch --depth 1 https://github.com/siplabs/monster-ui-apiexplorer apiexplorer
			popd

			log::m-info "Cleaning up monster-ui apps ..."
			# we only need these files for the metadata that will be loaded when running init apps
			npm uninstall

			find dist/apps -mindepth 2 -maxdepth 2 -not -name i18n -not -name metadata -exec rm -rf {} \;
			find dist -mindepth 1 -maxdepth 1 -not -name apps -exec rm -rf {} \;
			find -mindepth 1 -maxdepth 1 -not -name dist -exec rm -rf {} \;

			mkdir -p /var/www/html/monster-ui
			mv dist/* $_
			popd && rm -rf $OLDPWD


log::m-info "Removing npm and gulp ..."
npm uninstall -g npm gulp
rm -rf ~/.{npm,v8*} /tmp/npm*


log::m-info "Cleaning up unneeded packages ..."
apt-get purge -y --auto-remove \
	binutils \
	build-essential \
	cpp \
	ca-certificates \
	expat \
	git \
	lsb-release \
	make \
	nodejs \
	python \
    unzip \
    wget \
    zip

rm -f /etc/apt/sources.list.d/nodesource.list


log::m-info "Removing erlang ..."
kerl_deactivate
kerl delete installation r${ERLANG_VERSION} || true
kerl delete build r${ERLANG_VERSION} || true
kerl cleanup all
rm -rf /usr/lib/erlang


log::m-info "Removing kerl ..."
rm -rf /usr/bin/kerl ~/.kerl*


log::m-info "Adding app init to entrypoint.d ..."
tee /etc/entrypoint.d/50-${APP}-init <<'EOF'
# write the erlang cookie
erlang-cookie write

# ref: http://erlang.org/doc/apps/erts/crash_dump.html
erlang::set-erl-dump
EOF


log::m-info "Adding erts directory to paths.d ..."
echo "~/erts-$(cat ~/releases/RELEASES | head -1 | cut -d',' -f4 | xargs)/bin" >> /etc/paths.d/20-${APP}


log::m-info "Adding ${APP}-env to environment.d ..."
tee /etc/environment.d/40-${APP}-env <<EOF
ERTS_DIR=~/erts-$(cat ~/releases/RELEASES | head -1 | cut -d',' -f4 | xargs)
KAZOO_RELEASE=$(cat ~/releases/RELEASES | head -1 | cut -d',' -f3 | xargs)
ERTS_VERSION=$(cat ~/releases/RELEASES | head -1 | cut -d',' -f4 | xargs)
ERL_CRASH_DUMP=\$(date +%s)_\${ERLANG_VM}_erl_crash.dump
LD_LIBRARY_PATH=$HOME/erts-$ERTS_VERSION/lib:\$LD_LIBRARY_PATH
ERTS_LIB_DIR=$HOME/lib
EOF


log::m-info "Adding /etc/kazoo to fixattrs.d ..."
tee /etc/fixattrs.d/20-${APP}-perms <<EOF
/etc/kazoo true $USER:$USER 0644 0755
EOF


log::m-info "Creating Directories ..."
mkdir -p \
    ~/log \
    /var/run/kazoo \
    /var/log/kazoo


log::m-info "Setting Ownership & Permissions ..."
chown -R $USER:$USER \
	~ \
	/etc/kazoo \
	/var/log/kazoo \
	/var/run/kazoo \
	/var/www/html


log::m-info "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
