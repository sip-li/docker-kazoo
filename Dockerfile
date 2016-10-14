FROM    callforamerica/debian

MAINTAINER joe <joe@valuphone.com>

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

ENV     ERLANG_VERSION=${ERLANG_VERSION:-18.3} \
        KAZOO_VERSION=${KAZOO_VERSION:-4.0} \
        KAZOO_BRANCH=${KAZOO_BRANCH:-master} \
        KAZOO_CONFIGS_BRANCH=${KAZOO_CONFIGS_BRANCH:-master} \
        KAZOO_SOUNDS_BRANCH=${KAZOO_SOUNDS_BRANCH:-master} \
        MONSTER_UI_BRANCH=${MONSTER_UI_BRANCH:-master} \
        MONSTER_APPS_VERSION=${MONSTER_APPS_VERSION:-4.0} \
        MONSTER_APPS_BRANCH=${MONSTER_APPS_BRANCH:-master} \
        MONSTER_APPS=${MONSTER_APPS:-callflows,voip,pbxs,accounts,webhooks,numbers} \
        MONSTER_APP_APIEXPLORER_BRANCH=${MONSTER_APP_APIEXPLORER_BRANCH:-master} \
        NODE_VERSION=${NODE_VERSION:-6} \
        KERL_CONFIGURE_OPTIONS=${KERL_CONFIGURE_OPTIONS:-'--disable-hipe --without-odbc --without-javac'}

LABEL   lang.erlang.version=$ERLANG_VERSION

LABEL   app.kazoo.version=$KAZOO_VERSION \
        app.kazoo.branch=$KAZOO_BRANCH

LABEL   app.monster-apps.version=$MONSTER_APPS_VERSION \
        app.monster-apps.branch=$MONSTER_APPS_BRANCH \
        app.monster-apps.apps="${MONSTER_APPS},apiexplorer"

ENV     HOME=/opt/kazoo

COPY    build.sh /tmp/
RUN     /tmp/build.sh

COPY    entrypoint /
COPY    kazootool $HOME/bin/

ENV     ERLANG_VM=kazoo_apps \
        KAZOO_LOG_LEVEL=info

EXPOSE  4369 5555 8000 11500-11999 19025 24517

WORKDIR /opt/kazoo

ENTRYPOINT  ["/dumb-init", "--"]
CMD         ["/entrypoint"]
