#!/bin/bash

set -e

app=kazoo
user=$app

# Use local cache proxy if it can be reached, else nothing.
eval $(detect-proxy enable)


echo "Creating user and group for $user ..."
useradd --system --home-dir ~ --create-home --shell /bin/false --user-group $user


echo "Installing essentials ..."
apt-get update
apt-get install -y curl ca-certificates bash-completion


echo "Installing dependencies ..."
apt-get install -y \
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


echo "Installing kerl ..."
curl -sSL -o /usr/bin/kerl \
	https://raw.githubusercontent.com/yrashk/kerl/master/kerl
chmod +x /usr/bin/kerl


# echo "Installing erlang repo ..."
# apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 434975BD900CCBE4F7EE1B1ED208507CA14F4FCA
# echo 'deb http://packages.erlang-solutions.com/debian jessie contrib' > /etc/apt/sources.list.d/erlang.list
# apt-get update

echo "Installing erlang $ERLANG_VERSION ..."
export KERL_CONFIGURE_OPTIONS
kerl build $ERLANG_VERSION r${ERLANG_VERSION}
kerl install $_ /usr/lib/erlang
. /usr/lib/erlang/activate


echo "Installing kazoo ..."
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


echo "Installing kazoo-configs ..."
cd /tmp
	git clone -b $KAZOO_CONFIGS_BRANCH --single-branch --depth 1 https://github.com/2600hz/kazoo-configs kazoo-configs
	pushd $_
		find -mindepth 1 -maxdepth 1 -not -name system -not -name core -exec rm -rf {} \;
		#mv system/sbin/{kazoo-applications,kazoo-ecallmgr} /usr/sbin/
		mkdir -p /etc/kazoo/core
		mv core/* $_
		popd && rm -rf $OLDPWD


echo "Installing kazoo-sounds ..."
cd /tmp
	git clone -b $KAZOO_SOUNDS_BRANCH --single-branch --depth 1 https://github.com/2600hz/kazoo-sounds kazoo-sounds
	pushd $_
		mkdir -p ~/media/prompts
		mv kazoo-core/* $_
		popd && rm -rf $OLDPWD


echo "Installing nodejs v$NODE_VERSION ..."
curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt-get install -y nodejs


echo "Installing node packages ..."
npm install -g npm gulp


echo "Installing monster-ui ..."
mkdir -p /var/www/html/monster-ui
cd /tmp
	git clone -b $MONSTER_APPS_BRANCH --single-branch --depth 1 https://github.com/2600hz/monster-ui monster-ui
	pushd $_
		echo "Installing monster-ui apps ..."
		pushd src/apps
			for app in $(echo "${MONSTER_APPS//,/ }")
			do
				git clone -b $MONSTER_APPS_BRANCH --single-branch --depth 1 https://github.com/2600hz/monster-ui-${app} $app
			done
			popd
		npm install
		gulp build-prod
		pushd dist/apps
			git clone -b $MONSTER_APP_APIEXPLORER_BRANCH --single-branch --depth 1 https://github.com/siplabs/monster-ui-apiexplorer apiexplorer
			popd

			echo "Cleaning up monster-ui apps ..."
			# we only need these files for the metadata that will be loaded when running init apps
			npm uninstall 

			find dist/apps -mindepth 2 -maxdepth 2 -not -name i18n -not -name metadata -exec rm -rf {} \;
			find dist -mindepth 1 -maxdepth 1 -not -name apps -exec rm -rf {} \;
			find -mindepth 1 -maxdepth 1 -not -name dist -exec rm -rf {} \;

			mkdir -p /var/www/html/monster-ui
			mv dist/* $_
			popd && rm -rf $OLDPWD


echo "Creating Directories ..."
mkdir -p ~/log /var/run/kazoo /var/log/kazoo


echo "Adding some environment variables and erts bin dir to PATH ..."
tee  /etc/profile.d/90-kazoo-erts-bin-path.sh <<EOF
export ERTS_DIR=~/erts-$(cat ~/releases/RELEASES | head -1 | cut -d',' -f4 | xargs)

if [[ -d \$ERTS_DIR/bin ]]
then
	export PATH=\$ERTS_DIR/bin:$PATH
fi
EOF

echo "Adding sup wrapper ..."
tee /usr/local/bin/sup <<'EOF'
#!/bin/bash -l

: ${ERLANG_COOKIE:=$(cat ~/.erlang.cookie)}

/bin/sup -c $ERLANG_COOKIE $@
EOF


echo "Removing npm and gulp ..."
npm uninstall -g npm gulp
rm -rf ~/.{npm,v8*} /tmp/npm*


echo "Cleaning up unneeded packages ..."
apt-get purge -y --auto-remove \
	binutils \
	build-essential \
	cpp \
	curl \
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


echo "Removing erlang ..."
kerl_deactivate
kerl delete installation r${ERLANG_VERSION} || true
kerl delete build r${ERLANG_VERSION} || true
kerl cleanup all
rm -rf /usr/lib/erlang


echo "Removing kerl ..."
rm -rf /usr/bin/kerl ~/.kerl*


echo "Setting Ownership & Permissions ..."
chown -R kazoo:kazoo \
	~ \
	/etc/kazoo \
	/var/log/kazoo \
	/var/run/kazoo \
	/var/www/html

chmod +x /usr/local/bin/sup


echo "Cleaning up ..."
apt-clean --aggressive

# if applicable, clean up after detect-proxy enable
eval $(detect-proxy disable)

rm -r -- "$0"
