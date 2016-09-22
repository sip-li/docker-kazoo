#!/bin/bash

set -e

ARCH=x86_64
MONSTER_APPS=(callflows voip pbxs accounts webhooks numbers)


echo "Setting up locales ..."
apt-get update -y
apt-get install --no-install-recommends -y locales

sed -ir '/en_US\.UTF-8 UTF-8/s/# //' /etc/locale.gen
echo 'LANG="en_US.UTF-8"'> /etc/default/locale

dpkg-reconfigure --frontend=noninteractive locales

update-locale LC_ALL='en_US.UTF-8'
update-locale LANG='en_US.UTF-8'
update-locale LANGUAGE='en_US.UTF-8'


echo "Installing essentials ..."
apt-get install -y \
    vim \
    curl


echo "Installing dependencies ..."
apt-get install --no-install-recommends -y build-essential 

apt-get install --no-install-recommends -y \
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


echo "Installing erlang $ERLANG_VERSION ..."
kerl build $ERLANG_VERSION r${ERLANG_VERSION}
kerl install r${ERLANG_VERSION} /usr/lib/erlang
. /usr/lib/erlang/activate

cd /etc
	git clone --depth 1 https://github.com/2600hz/kazoo-configs/ kazoo

rm -rf /opt/kazoo
cd /opt
	git clone -b $KAZOO_VERSION --single-branch --depth 1 https://github.com/2600Hz/kazoo
	cd kazoo
		make
		# make build-release
		make sup_completion

		ln -s /opt/kazoo/sup.bash /etc/bash_completion.d/sup.bash
		ln -s /opt/kazoo/core/sup/priv/sup /usr/bin/sup


echo "Creating user and group for kazoo ..."
addgroup kazoo
adduser --home ~ --no-create-home --ingroup kazoo --shell /bin/bash --gecos "kazoo user" --disabled-password kazoo


echo "Creating monsterui home directory ..."
mkdir -p ~ /var/www/html


echo "Installing nodejs v$NODE_VERSION ..."
curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt-get install --no-install-recommends -y nodejs


echo "Installing node packages ..."
npm install -g npm gulp


echo "Installing monster-ui ..."
mkdir -p /tmp/monster /var/www/html/monster-ui
cd /tmp/monster

	git clone -b $MONSTER_UI_VERSION --single-branch --depth 1 https://github.com/2600hz/monster-ui

	echo "Installing monster-ui apps ..."
	cd monster-ui/src/apps
	for app in "${MONSTER_APPS[@]}"
	do
		git clone -b $MONSTER_UI_VERSION https://github.com/2600hz/monster-ui-${app} $app
	done

		cd ../../
			npm install
			gulp build-prod

			cd dist/apps
				git clone --single-branch --depth 1 \
					https://github.com/siplabs/monster-ui-apiexplorer apiexplorer
				cd ..
					mv * /var/www/html/monster-ui
					cd / && rm -rf /tmp/monster


echo "Installing gosu ..."
curl -sSL -o /usr/local/bin/gosu \
    https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64


echo "Installing dumb-init ..."
curl -sSL -o /dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_amd64


echo "Creating Directories ..."
mkdir -p ~/bin /var/run/kazoo


echo "Cleaning up unneeded packages ..."
npm uninstall -g npm gulp

apt-get purge -y \
	build-essential \
	cpp \
	make \
	binutils \
	expat \
	git \
	nodejs \
	python \
    unzip \
    wget \
    zip

apt-get autoremove -y


echo "Writing Hostname override fix ..."
tee ~/bin/hostname-fix <<'EOF'
#!/bin/bash

fqdn() {
	local IP=$(/bin/hostname -i | cut -d' ' -f1 | sed 's/\./-/g')
	local DOMAIN='default.pod.cluster.local'
	echo "${IP}.${DOMAIN}"
}

short() {
    local IP=$(/bin/hostname -i | cut -d' ' -f1 | sed 's/\./-/g')
    echo $IP
}

ip() {
	/bin/hostname -i
}

if [[ "$1" == "-f" ]]; then
	fqdn
elif [[ "$1" == "-s" ]]; then
	short
elif [[ "$1" == "-i" ]]; then
	ip
else
	short
fi
EOF


echo "Writing .bashrc ..."
tee ~/.bashrc <<'EOF'
#!/bin/bash

if [ "$KUBERNETES_HOSTNAME_FIX" == true ]; then
	ln -sf ~/bin/hostname-fix ~/bin/hostname
    export HOSTNAME=$(hostname -f)
fi

TERM=xterm-256color
COLS=80
LINES=64

c_rst='\[\e[0m\]'
c_c='\[\e[36m\]'
c_g='\[\e[92m\]'
PS1="[\$(hostname) ${c_g}\W${c_rst}] $ "

LS_COLORS='rs=0:di=38;5;27:ln=38;5;51:mh=44;38;5;15:pi=40;38;5;11:so=38;5;13:do=38;5;5:bd=48;5;232;38;5;11:cd=48;5;232;38;5;3:or=48;5;232;38;5;9:mi=05;48;5;232;38;5;15:su=48;5;196;38;5;15:sg=48;5;11;38;5;16:ca=48;5;196;38;5;226:tw=48;5;10;38;5;16:ow=48;5;10;38;5;21:st=48;5;21;38;5;15:ex=38;5;34:*.tar=38;5;9:*.tgz=38;5;9:*.arc=38;5;9:*.arj=38;5;9:*.taz=38;5;9:*.lha=38;5;9:*.lz4=38;5;9:*.lzh=38;5;9:*.lzma=38;5;9:*.tlz=38;5;9:*.txz=38;5;9:*.tzo=38;5;9:*.t7z=38;5;9:*.zip=38;5;9:*.z=38;5;9:*.Z=38;5;9:*.dz=38;5;9:*.gz=38;5;9:*.lrz=38;5;9:*.lz=38;5;9:*.lzo=38;5;9:*.xz=38;5;9:*.bz2=38;5;9:*.bz=38;5;9:*.tbz=38;5;9:*.tbz2=38;5;9:*.tz=38;5;9:*.deb=38;5;9:*.rpm=38;5;9:*.jar=38;5;9:*.war=38;5;9:*.ear=38;5;9:*.sar=38;5;9:*.rar=38;5;9:*.alz=38;5;9:*.ace=38;5;9:*.zoo=38;5;9:*.cpio=38;5;9:*.7z=38;5;9:*.rz=38;5;9:*.cab=38;5;9:*.jpg=38;5;13:*.jpeg=38;5;13:*.gif=38;5;13:*.bmp=38;5;13:*.pbm=38;5;13:*.pgm=38;5;13:*.ppm=38;5;13:*.tga=38;5;13:*.xbm=38;5;13:*.xpm=38;5;13:*.tif=38;5;13:*.tiff=38;5;13:*.png=38;5;13:*.svg=38;5;13:*.svgz=38;5;13:*.mng=38;5;13:*.pcx=38;5;13:*.mov=38;5;13:*.mpg=38;5;13:*.mpeg=38;5;13:*.m2v=38;5;13:*.mkv=38;5;13:*.webm=38;5;13:*.ogm=38;5;13:*.mp4=38;5;13:*.m4v=38;5;13:*.mp4v=38;5;13:*.vob=38;5;13:*.qt=38;5;13:*.nuv=38;5;13:*.wmv=38;5;13:*.asf=38;5;13:*.rm=38;5;13:*.rmvb=38;5;13:*.flc=38;5;13:*.avi=38;5;13:*.fli=38;5;13:*.flv=38;5;13:*.gl=38;5;13:*.dl=38;5;13:*.xcf=38;5;13:*.xwd=38;5;13:*.yuv=38;5;13:*.cgm=38;5;13:*.emf=38;5;13:*.axv=38;5;13:*.anx=38;5;13:*.ogv=38;5;13:*.ogx=38;5;13:*.aac=38;5;45:*.au=38;5;45:*.flac=38;5;45:*.mid=38;5;45:*.midi=38;5;45:*.mka=38;5;45:*.mp3=38;5;45:*.mpc=38;5;45:*.ogg=38;5;45:*.ra=38;5;45:*.wav=38;5;45:*.axa=38;5;45:*.oga=38;5;45:*.spx=38;5;45:*.xspf=38;5;45:'

: ${LC_ALL:=en_US.utf8}
: ${LANG:=en_US.utf8}
: ${LANGUAGE:=en_US.utf8}

PATH=/usr/lib/erlang/bin:$PATH
export TERM COLS LINES LC_ALL LANG LANGUAGE LS_COLORS PS1 PATH

alias ls='ls --color'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
EOF


echo "Setting Ownership & Permissions ..."
chown -R kazoo:kazoo ~ /var/run/kazoo /var/www/html

chmod +x \
	~/.bashrc \
	~/bin/hostname-fix \
	/usr/local/bin/gosu \
	/dumb-init


echo "Cleaning up ..."
apt-get clean
rm -rf /var/lib/apt/lists/*

rm -r /tmp/setup.sh
