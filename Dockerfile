FROM telephoneorg/debian:stretch

MAINTAINER Joe Black <me@joeblack.nyc>

ARG     KAZOO_BRANCH

ENV     KAZOO_BRANCH ${KAZOO_BRANCH:-4.2}

LABEL   app.kazoo.core.branch=$KAZOO_BRANCH

ENV     APP kazoo
ENV     USER $APP
ENV     HOME /opt/$APP

COPY    build.sh /tmp/
RUN     /tmp/build.sh

COPY    entrypoint /
COPY    build/kazoo-tool /usr/local/bin/
COPY    build/sup /usr/local/bin/

ENV     ERL_MAX_PORTS 65536
ENV     ERLANG_VM kazoo_apps
ENV     ERLANG_THREADS 64
ENV     ERLANG_HOSTNAME long

# options: debug info notice warning error critical alert emergency
ENV     KAZOO_LOG_LEVEL info
ENV     KAZOO_LOG_COLOR true
ENV     KAZOO_APPS blackhole,callflow,cdr,conference,crossbar,doodle,ecallmgr,fax,hangups,hotornot,konami,jonny5,media_mgr,milliwatt,omnipresence,pivot,registrar,reorder,stepswitch,sysconf,teletype,trunkstore,webhooks

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
