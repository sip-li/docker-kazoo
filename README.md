# Kazoo 4.x (Open Source)
## w/ Kubernetes fixes & manifests
[![Build Status](https://travis-ci.org/telephoneorg/docker-kazoo.svg?branch=master)](https://travis-ci.org/telephoneorg/docker-kazoo) [![Docker Pulls](https://img.shields.io/docker/pulls/telephoneorg/kazoo.svg)](https://hub.docker.com/r/telephoneorg/kazoo/) [![Size/Layers](https://images.microbadger.com/badges/image/telephoneorg/kazoo.svg)](https://microbadger.com/images/telephoneorg/kazoo) [![Github Repo](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/telephoneorg/docker-couchdb)


## Maintainer
Joe Black | <me@joeblack.nyc> | [github](https://github.com/joeblackwaslike)


## Description
Minimal image with kazoo, monster-ui, monster-apps, & kazoo-sounds.  This image uses a custom, minimal version of Debian Linux.

##### Useful links:
* 2600hz Github: https://github.com/2600hz/kazoo
* 4.2.x sup-commands: https://gist.github.com/joeblackwaslike/345b9eb3b81d6033d26aaf1953c0f4fe


## Introduction
The aim of this project is combine or experience running Kazoo in docker in a way that lowers the barrier of entry for others.

We target a local docker only environment using docker-compose and a production environment using Kubernetes as the cluster manager.  We reccomend the same but effort has been made to ensure this image is flexible and contains enough environment variables to allow significant customization to your needs.

Pull requests with improvements always welcome.


## Build Environment
The build environment has been split off from this repo and now lives @ https://github.com/telephoneorg/kazoo-builder.  See the README.md file there for more details on the build environment.


The following variables are standard in most of our Dockerfiles to reduce duplication and make scripts reusable among different projects:
* `APP`: kazoo
* `USER`: kazoo
* `HOME` /opt/kazoo


## Run Environment
Run environment variables are used in the entrypoint script to render configuration templates, perform flow control, etc.  These values can be overridden when inheriting from the base dockerfile, specified during `docker run`, or in kubernetes manifests in the `env` array.
* `KAZOO_APPS`: a comma delimited list used directly by the kazoo_apps erlang vm as the list of default apps to start.
* `ERLANG_THREADS`: passed to the `+A` argument in vm.args.
* `ERLANG_COOKIE`:  written to `~/.erlang.cookie` by the `erlang-cookie` script in `/usr/local/bin`.
* `KAZOO_LOG_LEVEL`: lowercased and used as the value for the console log level in the log section of `config.ini`.
* `KAZOO_LOG_COLOR`: used as the value for the `colored` tuple in `sys.config`.
* `REGION`: interpolated with `DATACENTER` as such `${COUNTRY}-${REGION}` and stored in `KAZOO_ZONE`.  See `KAZOO_ZONE`.
* `COUNTRY`: interpolated with `REGION` as such `${COUNTRY}-${REGION}` and stored in `KAZOO_ZONE`.  See `KAZOO_ZONE`.
* `KAZOO_ZONE`: when provided, interpolation of `COUNTRY` and `REGION` is ignored and the value of `KAZOO_ZONE` is used directly. This is useful for local test and dev environments where ZONE's don't matter.  Used as name in `[zone]` section and as `zone` attribute in other sections of `config.ini`.
* `COUCHDB_HOST`: the hostname or ip address of the load balancer to reach bigcouch or couchdb through. Used in the `bigcouch` section of `config.ini`.
* `COUCHDB_DATA_PORT`: used as the value for the `port` key in the `bigcouch` section of `config.ini`.
* `COUCHDB_ADMIN_PORT`: used as the value for the `admin_port` key in the `bigcouch` section of `config.ini`.
* `COUCHDB_USER`: used as the value for the `username` key in the `bigcouch` section of `config.ini`.
* `COUCHDB_PASS`: used as the value for the `password` key in the `bigcouch` section of `config.ini`.
* `RABBITMQ_USER`: interpolated as such `"amqp://user:pass@host:5672"` and used for all `uri` keys in the `amqp` section or the `amqp_uri` keys in the `zone` section of `config.ini`.
* `RABBITMQ_PASS`: interpolated as such `"amqp://user:pass@host:5672"` and used for all `uri` keys in the `amqp` section or the `amqp_uri` keys in the `zone` section of `config.ini`.
* `RABBITMQ_HOST`: hostname or ip address, interpolated as such `"amqp://{user}:{pass}@{host}:5672"`, and used in the `amqp_uri` property of the `zone` section of `config.ini`.


## Extra tools
### In container
There is a binary called [kazoo-tool](build/kazoo-tool) in `~/bin`.  It contains the useful functions such as remote_console, upgrade, etc found in the original kazoo service file.  Since using service files in a docker container is largely a very bad idea, I've extracted the useful functions and adapted them to work in the container environment.


## Usage
### Under docker
All of our docker-* repos in github have CI pipelines that push to docker cloud/hub.

This image is available at:
* [https://store.docker.com/community/images/telephoneorg/kazoo](https://store.docker.com/community/images/telephoneorg/kazoo)
*  [https://hub.docker.com/r/telephoneorg/kazoo](https://hub.docker.com/r/telephoneorg/kazoo).
* `docker pull telephoneorg/kazoo`

To run:
```bash
docker run -d \
    --name kazoo \
    -h kazoo.local \
    -e "COUCHDB_HOST=bigcouch.local" \
    -e "RABBITMQ_HOST=rabbitmq.local" \
    -e "KAZOO_LOG_LEVEL=debug" \
    -e "KAZOO_APPS=blackhole,callflow,cdr,conference,crossbar,doodle,ecallmgr,hangups,hotornot,konami,jonny5,media_mgr,milliwatt,omnipresence,pivot,registrar,reorder,stepswitch,sysconf,teletype,trunkstore,webhooks" \
    -e "ERLANG_COOKIE=test-cookie" \
    -p "8000:8000" \
    telephoneorg/kazoo
```

**NOTE:** Please reference the Run Environment section for the list of available environment variables.


### Under docker-compose
Pull the images
```bash
docker-compose pull
```

Start application and dependencies
```bash
# start in foreground
docker-compose up --abort-on-container-exit

# start in background
docker-compose up -d
```


### Under Kubernetes
Edit the manifests under `kubernetes/<environment>` to reflect your specific environment and configuration.

Create a secret for the erlang cookie:
```bash
kubectl create secret generic erlang --from-literal=cookie=$(LC_ALL=C tr -cd '[:alnum:]' < /dev/urandom | head -c 64)
```

Ensure that:
* Secrets exist for the `rabbitmq` and `couchdb` credentials, otherwise supply them directly in the env array of the pod template.
* rabbitmq deployment and couchdb statefulset is running.  This container will be paused by the kubewait init-container until it's service dependencies exist and pass readiness-checks.


Deploy kazoo:
```bash
kubectl create -f kubernetes/<environment>
```
