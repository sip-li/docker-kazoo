FROM telephoneorg/debian:stretch

MAINTAINER Joe Black <me@joeblack.nyc>

ARG     KAZOO_VERSION
ARG     KAZOO_CONFIGS_VERSION
ENV     KAZOO_VERSION ${KAZOO_VERSION:-4.1.43}
ENV     KAZOO_CONFIGS_VERSION ${KAZOO_CONFIGS_VERSION:-4.1.21}
LABEL   app.kazoo.core.version=$KAZOO_VERSION
LABEL   app.kazoo.configs.version=$KAZOO_CONFIGS_VERSION

ENV     APP kazoo
ENV     USER $APP
ENV     HOME /opt/$APP

COPY    build.sh /tmp/
RUN     /tmp/build.sh

COPY    entrypoint /
COPY    kazoo-tool /usr/local/bin/
COPY    sup /usr/local/bin/

VOLUME  ["/var/www/html/monster-ui", "/opt/kazoo/media/prompts"]

ENV     ERL_MAX_PORTS 16192
ENV     ERLANG_VM kazoo_apps
ENV     ERLANG_HOSTNAME long

# options: debug info notice warning error critical alert emergency
ENV     KAZOO_LOG_LEVEL info
ENV     KAZOO_LOG_COLOR true
ENV     KAZOO_APPS blackhole,callflow,cdr,conference,crossbar,doodle,ecallmgr,hangups,hotornot,konami,jonny5,media_mgr,milliwatt,omnipresence,pivot,registrar,reorder,stepswitch,sysconf,tasks,teletype,trunkstore,webhooks

ENV     COUCHDB_HOST couchdb
ENV     COUCHDB_DATA_PORT 5984
ENV     COUCHDB_ADMIN_PORT 5986
ENV     COUCHDB_USER admin
ENV     COUCHDB_PASS secret

ENV     RABBITMQ_HOSTS rabbitmq
ENV     RABBITMQ_USER guest
ENV     RABBITMQ_PASS guest

ENV     REGION local
ENV     DATACENTER dev

EXPOSE  5555 5555/udp 8000 19025 24517

WORKDIR $HOME

SHELL       ["/bin/bash", "-lc"]
HEALTHCHECK --interval=15s --timeout=5s \
    CMD curl -f -s http://localhost:8000 || exit 1

ENTRYPOINT  ["/dumb-init", "--"]
CMD         ["/entrypoint"]
