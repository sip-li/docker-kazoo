FROM callforamerica/debian

MAINTAINER Joe Black <joeblack949@gmail.com>

ARG     ERLANG_VERSION
ARG     KAZOO_VERSION
ARG     KAZOO_BRANCH
ARG     KAZOO_CONFIGS_BRANCH
ARG     KAZOO_SOUNDS_BRANCH
ARG     MONSTER_UI_BRANCH
ARG     MONSTER_APPS_VERSION
ARG     MONSTER_APPS
ARG     MONSTER_APPS_BRANCH
ARG     MONSTER_APP_APIEXPLORER_BRANCH
ARG     NODE_VERSION
ARG     KERL_CONFIGURE_OPTIONS

ENV     ERLANG_VERSION=${ERLANG_VERSION:-18.3}
ENV     KAZOO_VERSION=${KAZOO_VERSION:-4.0}
ENV     KAZOO_BRANCH=${KAZOO_BRANCH:-$KAZOO_VERSION}
ENV     KAZOO_CONFIGS_BRANCH=${KAZOO_CONFIGS_BRANCH:-4.0}
ENV     KAZOO_SOUNDS_BRANCH=${KAZOO_SOUNDS_BRANCH:-4.0}
ENV     MONSTER_UI_BRANCH=${MONSTER_UI_BRANCH:-4.0}
ENV     MONSTER_APPS_VERSION=${MONSTER_APPS_VERSION:-4.0}
ENV     MONSTER_APPS_BRANCH=${MONSTER_APPS_BRANCH:-$MONSTER_APPS_VERSION}
ENV     MONSTER_APPS=${MONSTER_APPS:-accounts,callflows,fax,numbers,pbxs,voip,voicemails,webhooks}
ENV     MONSTER_APP_APIEXPLORER_BRANCH=${MONSTER_APP_APIEXPLORER_BRANCH:-master}
ENV     NODE_VERSION=${NODE_VERSION:-6}
ENV     KERL_CONFIGURE_OPTIONS=${KERL_CONFIGURE_OPTIONS:-'--disable-hipe --without-odbc --without-javac'}

LABEL   lang.erlang.version=$ERLANG_VERSION
LABEL   app.kazoo.version=$KAZOO_VERSION
LABEL   app.kazoo.branch=$KAZOO_BRANCH

LABEL   app.monster-apps.version=$MONSTER_APPS_VERSION
LABEL   app.monster-apps.branch=$MONSTER_APPS_BRANCH
LABEL   app.monster-apps.apps="${MONSTER_APPS},apiexplorer"

ENV     APP kazoo
ENV     USER $APP
ENV     HOME /opt/$APP

COPY    build.sh /tmp/
RUN     /tmp/build.sh

COPY    entrypoint /
COPY    build/kazoo-tool $HOME/bin/
COPY    build/sup /usr/local/bin/
COPY    build/50-kazoo-functions.sh /etc/profile.d/

ENV     ERL_MAX_PORTS 65536
ENV     ERLANG_VM kazoo_apps
ENV     ERLANG_THREADS 64

# options: debug info notice warning error critical alert emergency
ENV     KAZOO_LOG_LEVEL info
ENV     KAZOO_LOG_COLOR true

ENV     KAZOO_APPS blackhole,callflow,cdr,conference,crossbar,doodle,ecallmgr,fax,hangups,hotornot,konami,jonny5,media_mgr,milliwatt,omnipresence,pivot,registrar,reorder,stepswitch,sysconf,teletype,trunkstore,webhooks

ENV     KAZOO_SASL_ERRLOG_TYPE error
ENV     KAZOO_SASL_ERROR_LOGGER tty

ENV     COUCHDB_HOST couchdb
ENV     COUCHDB_DATA_PORT 5984
ENV     COUCHDB_ADMIN_PORT 5986
ENV     COUCHDB_COMPACT_AUTOMATICALLY true
ENV     COUCHDB_USER admin
ENV     COUCHDB_PASS secret

ENV     KAZOO_AMQP_HOSTS rabbitmq
ENV     RABBITMQ_USER guest
ENV     RABBITMQ_PASS guest

ENV     REGION local
ENV     DATACENTER dev

EXPOSE  5555 5555/udp 8000 19025 24517

WORKDIR $HOME

SHELL       ["/bin/bash"]
HEALTHCHECK --interval=15s --timeout=5s \
    CMD curl -f -s http://localhost:8000 || exit 1

ENTRYPOINT  ["/dumb-init", "--"]
CMD         ["/entrypoint"]
