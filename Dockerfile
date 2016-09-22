FROM debian:jessie

MAINTAINER joe <joe@valuphone.com>

LABEL   os="linux" \
        os.distro="debian" \
        os.version="jessie"

LABEL   lang.name="erlang" \
        lang.version="18.3"

LABEL   app.name="kazoo" \
        app.version="4.0"

ENV     ERLANG_VERSION=18.3 \
        KAZOO_VERSION=master \
        MONSTER_UI_VERSION=master \
        NODE_VERSION=6 \
        GOSU_VERSION=1.9 \
        DUMB_INIT_VERSION=1.1.3

ENV     HOME=/opt/kazoo
ENV     PATH=$HOME/bin:$PATH

COPY    setup.sh /tmp/setup.sh
RUN     /tmp/setup.sh

COPY    entrypoint /usr/bin/entrypoint

ENV     ERLANG_VM=kazoo_apps \
        KAZOO_LOG_LEVEL=info

EXPOSE  4369 5555 8000 11500-11999

# USER    kazoo

WORKDIR /opt/kazoo

ENTRYPOINT  ["/dumb-init", "--"]
CMD         ["/usr/bin/entrypoint"]
