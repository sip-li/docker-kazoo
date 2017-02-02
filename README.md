# Kazoo 4.0 w/ Kubernetes fixes & manifests

[![Build Status](https://travis-ci.org/sip-li/docker-kazoo.svg?branch=master)](https://travis-ci.org/sip-li/docker-kazoo) [![Docker Pulls](https://img.shields.io/docker/pulls/callforamerica/kazoo.svg)](https://store.docker.com/community/images/callforamerica/kazoo)

## Maintainer

Joe Black <joeblack949@gmail.com>

## Description

Minimal image with monster-ui apps.  This image uses a custom version of Debian Linux (Jessie) that I designed weighing in at ~22MB compressed.

## Introduction

The aim of this project is to make running kazoo in a dockerized environment easy for everyone and combine all the experience we've learned running kazoo in docker in a way that lowers the barrier of entry to others wanting to run kazoo under docker.  We target both a local docker only environment and a production environment using Kubernetes as a cluster manager.  We reccomend the same but also have made the effort to make this flexible enough to be usable under a variety of cluster managers or even none at all.

Pull requests with improvements always welcome.

## Build Environment

Build environment variables are often used in the build script to bump version numbers and set other options during the docker build phase.  Their values can be overridden using a build argument of the same name.

* `ERLANG_VERSION`: supplied to kerl to select the version of erlang that is installed prior to kazoo being built. Defaults to `18.3`.

* `KAZOO_VERSION`: Informational purposes. Defaults to `4.0`.

* `KAZOO_BRANCH`: supplied to `git clone -b` when cloning the kazoo repo. Defaults to `4.0`.

* `KAZOO_CONFIGS_BRANCH`: supplied to `git clone -b` when cloning the kazoo-configs repo. Defaults to `4.0`.

* `KAZOO_SOUNDS_BRANCH`: supplied to `git clone -b` when cloning the kazoo-sounds repo. Defaults to `4.0`.

* `MONSTER_UI_BRANCH`: supplied to `git clone -b` when cloning the monster-ui repo. Defaults to `4.0`.

* `MONSTER_APPS_VERSION`: Informational purposes. Defaults to `4.0`.

* `MONSTER_APPS`: a comma delimited list of monster apps to clone/install.  Defaults to `accounts,callflows,fax,numbers,pbxs,voip,voicemails,webhooks`.

* `MONSTER_APPS_BRANCH`: supplied to `git clone -b` when cloning the monster-ui application repos. Defaults to `master`.

* `MONSTER_APP_APIEXPLORER_BRANCH`: supplied to `git clone -b` when cloning the monster-ui-apiexplorer repo. Defaults to `master`.

* `NODE_VERSION`: used to select the version of node.js to install. Defaults to `6`.

* `KERL_CONFIGURE_OPTIONS`: Used by kerl when building erlang, Defaults to `--disable-hipe --without-odbc --without-javac`.

The following variables are standard in most of our dockerfiles to reduce duplication and make scripts reusable among different projects:

* `APP`: kazoo
* `USER`: kazoo
* `HOME` /opt/kazoo


## Run Environment

Run environment variables are used in the entrypoint script to render configuration templates, perform flow control, etc.  These values can be overridden when inheriting from the base dockerfile, specified during `docker run`, or in kubernetes manifests in the `env` array.

* `KAZOO_APPS`: a comma delimited list used directly by the kazoo_apps erlang vm as the list of default apps to start. Defaults to `blackhole,callflow,cdr,conference,crossbar,doodle,ecallmgr,fax,hangups,hotornot,konami,jonny5,media_mgr,milliwatt,omnipresence,pivot,registrar,reorder,stepswitch,sysconf,teletype,trunkstore,webhooks`.

* `ERLANG_VM`: append `_app` to the end and passed to the `-s` argument in vm.args as well as used for the erlang node name. Defaults to `kazoo_apps`.

* `ERLANG_THREADS`: passed to the `+A` argument in vm.args.  Defaults to `64`.

* `ERLANG_COOKIE`:  written to `~/.erlang.cookie` by the `erlang-cookie` script in `/usr/local/bin`. Defaults to `insecure-cookie`.

* `KAZOO_LOG_LEVEL`: lowercased and used as the value for the console log level in the log section of `config.ini`  Defaults to `info`

* `KAZOO_LOG_COLOR`: used as the value for the `colored` tuple in `sys.config`.  Defaults to `true`

* `KAZOO_SASL_ERRLOG_TYPE`: used as the value for `-sasl errlog_type` in `vm.args`. Defaults to `error`, choices include: error, progress, all.

* `KAZOO_SASL_ERROR_LOGGER`: used as the value for `-sasl sasl_error_logger` in `vm.args`.  Defaults to `tty`.  *This shouldn't be changed without good reason inside docker and is provided for testing purposes*

* `REGION`: interpolated with `DATACENTER` as such `${REGION}-${DATACENTER}` and stored in `KAZOO_ZONE`.  See `KAZOO_ZONE`.  Defaults to local.

* `DATACENTER`: interpolated with `REGION` as such `${REGION}-${DATACENTER}` and stored in `KAZOO_ZONE`.  See `KAZOO_ZONE`.  Defaults to dev.

* `KAZOO_ZONE`: when provided, interpolation of `DATACENTER` and `REGION` is ignored and the value of `KAZOO_ZONE` is used directly. This is useful for local test and dev environments where ZONE's don't matter.  Used as name in `[zone]` section and as `zone` attribute in other sections of `config.ini`.  Defaults to the interpolation described.

* `COUCHDB_HOST`: the hostname or ip address of the load balancer to reach bigcouch or couchdb through. Used in the `bigcouch` section of `config.ini`.  Defaults to `couchdb-lb`.

* `COUCHDB_DATA_PORT`: used as the value for the `port` key in the `bigcouch` section of `config.ini`.  Defaults to `5984`.

* `COUCHDB_ADMIN_PORT`: used as the value for the `admin_port` key in the `bigcouch` section of `config.ini`.  Defaults to `5986`.

* `COUCHDB_COMPACT_AUTOMATICALLY`: used as the value for the `compact_automatically` key in the `bigcouch` section of `config.ini`.  Defaults to `true`.

* `COUCHDB_USER`: used as the value for the `username` key in the `bigcouch` section of `config.ini`.  Defaults to `admin`.

* `COUCHDB_PASS`: used as the value for the `password` key in the `bigcouch` section of `config.ini`.  Defaults to `secret`

* `RABBITMQ_USER`: interpolated as such `"amqp://user:pass@host:5672"` and used for all `uri` keys in the `amqp` section or the `amqp_uri` keys in the `zone` section of `config.ini`.  Defaults to `guest`.

* `RABBITMQ_PASS`: interpolated as such `"amqp://user:pass@host:5672"` and used for all `uri` keys in the `amqp` section or the `amqp_uri` keys in the `zone` section of `config.ini`.  Defaults to `guest`.

* `KAZOO_AMQP_HOSTS`: comma delimited list of hostnames or ip addresses that are split on comma's, interpolated as such `"amqp://user:pass@host:5672"`, and used to build a `amqp_uri` for the `zone` section of `config.ini`.  Defaults to `rabbitmq-alpha`.


## Extra tools

There is a binary called [kazootool](kazootool).  It contains the useful functions such as remote_console, upgrade, etc found in the original kazoo service file.  Since using service files in a docker container is a largely bad idea, I've extracted the useful functions and adapted them to work in the container environment.  Check it out


## Usage

### Under docker (manual-build)

If building and running locally, feel free to use the convenience targets in the included `Makefile`.

* `make build`: rebuilds the docker image.
* `make launch`: launch for testing.
* `make logs`: tail the logs of the container.
* `make shell`: exec's into the docker container interactively with tty and bash shell.
* `make test`: test's the launched container.
* *and many others...*


### Under docker (pre-built)

All of our docker-* repos in github have CI pipelines that push to docker cloud/hub.  

This image is available at:
* [https://store.docker.com/community/images/callforamerica/kazoo](https://store.docker.com/community/images/callforamerica/kazoo)
*  [https://hub.docker.com/r/callforamerica/kazoo](https://hub.docker.com/r/callforamerica/kazoo).

and through docker itself: `docker pull callforamerica/kazoo`

To run:

```bash
docker run -d \
    --name kazoo \
    -h kazoo.local \
    -e "COUCHDB_HOST=bigcouch.local" \
    -e "KAZOO_AMQP_HOSTS=rabbitmq-alpha.local,rabbitmq-beta.local" \
    -e "KAZOO_LOG_LEVEL=debug" \
    -p "8000:8000" \
    callforamerica/kazoo
```

**NOTE:** Please reference the Run Environment section for the list of available environment variables.


### Under Kubernetes

Edit the manifests under `kubernetes/` to reflect your specific environment and configuration.

Create a secret for the erlang cookie:
```bash
kubectl create secret generic erlang-cookie --from-literal=erlang.cookie=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 64)
```

*Ensure secrets also exist for the rabbitmq and couchdb credentials, else supply them directly in the env array of the pod template.*

*Ensure rabbitmq deployment and couchdb statefulset is running.  This container will be paused by the kubewait init container until it's dependencies exist and in the ready state.

Deploy kazoo:
```bash
kubectl create -f kubernetes
```


## Issues

**ref:**  [https://github.com/sip-li/docker-kazoo/issues](https://github.com/sip-li/docker-kazoo/issues)
