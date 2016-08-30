FROM centos:6

MAINTAINER joe <joe@valuphone.com>

LABEL   os="linux" \
        os.distro="centos" \
        os.version="6"

LABEL   lang.name="erlang" \
        lang.version="R15B03"

LABEL   app.name="kazoo" \
        app.version="3.22"

ENV     ERLANG_VERSION=R15B03 \
        KAZOO_VERSION=3.22

ENV     HOME=/opt/kazoo
ENV     PATH=$HOME/bin:$PATH

COPY    setup.sh /tmp/setup.sh
RUN     /tmp/setup.sh

COPY    entrypoint /usr/bin/entrypoint

ENV     KAZOO_APP=whistle_apps \
        KAZOO_LOG_LEVEL=info

EXPOSE  4369 8000 11500-11999

# USER    kazoo

WORKDIR /opt/kazoo

CMD     ["/usr/bin/entrypoint"]
