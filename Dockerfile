FROM centos:6

MAINTAINER joe <joe@valuphone.com>

LABEL   os="linux" \
        os.distro="centos" \
        os.version="6"

LABEL   app.name="kazoo" \
        app.version="3"

ENV     TERM=xterm

COPY    setup.sh /tmp/setup.sh
RUN     /tmp/setup.sh

COPY    entrypoint /usr/bin/entrypoint

ENV     HOME=/opt/kazoo \
        PATH=/opt/kazoo/bin:$PATH \
        KUBERNETES_HOSTNAME_FIX=true \
        KAZOO_USE_LONGNAME=true

VOLUME  ["/opt/kazoo"]

EXPOSE  4369 8000 11500-11999

# USER    kazoo

WORKDIR /opt/kazoo

CMD     ["/usr/bin/entrypoint"]
