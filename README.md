# Kazoo v4.0 dockerized with kubernetes fixes and manifests

![docker automated build](https://img.shields.io/docker/automated/callforamerica/kazoo.svg)
![docker pulls](https://img.shields.io/docker/pulls/callforamerica/kazoo.svg)

## Maintainer

Joe Black <joe@valuphone.com>

## Introduction 

The aim of this docker project is to make running kazoo in a dockerized environment easy for everyone and combine all the experience we've learned running kazoo in docker in a way that lowers the barrier of entry to others wanting to run kazoo under docker.  We target both a local docker only environment and a production environment using kubernetes as a cluster manager.  We reccomend the same but also have made the effort to make this flexible enough to be usable under a variety of cluster managers or even none at all.

Pull requests with improvements always welcome.

## Build Environment

Build environment variables are used in the build script as plug in variables that can be set in the Dockerfile to bump version numbers of the various things that are installed during the `docker build` phase.

These variables can be overridden when building the image by providing additional `--build-arg` arguments to the docker build process

Example: `docker build -t project:tag --build-arg key=value -build-arg key2=value2.`

* `ERLANG_VERSION`: value provided is supplied to kerl and determines the version of erlang that is installed prior to kazoo being built. String, defaults to `18.3`.

* `KAZOO_VERSION`: value provided is not currently used. defaults to `4.0`.

* `KAZOO_BRANCH`: value provided is used as the -b argument when cloning the kazoo repo. defaults to `master`.

* `KAZOO_CONFIGS_BRANCH`: value provided is used as the -b argument when cloning the kazoo-configs repo. defaults to `master`.

* `KAZOO_SOUNDS_BRANCH`: value provided is used as the -b argument when cloning the kazoo-sounds repo. defaults to `master`.

* `MONSTER_UI_BRANCH`: value provided is used as the -b argument when cloning the monster-ui repo. defaults to `master`.

* `MONSTER_APPS_VERSION`: value provided is not currently used. defaults to defaults to `4.0`.

* `MONSTER_APPS`: value provided is a comma delimited list of the monster apps to install. defaults to defaults to `callflows,voip,pbxs,accounts,webhooks,numbers`.

* `MONSTER_APPS_BRANCH`: value provided is used as the -b argument when cloning the monster-ui application repo's. defaults to `master`.

* `MONSTER_APP_APIEXPLORER_BRANCH`: value provided is used as the -b argument when cloning the monster-ui-apiexplorer repo. defaults to `master`.

* `NODE_VERSION`: value provided is used as the version of node.js to install. String, defaults to `6`.

* `KERL_CONFIGURE_OPTIONS`: value is passed to kerl when building erlang, defaults to `--disable-hipe --without-odbc --without-javac`.

## Run Environment

Run environment variables are used in the [entrypoint script](entrypoint) when rendering configuration templates and sometimes also for flow control.  These values can be provided when inheriting from the base dockerfile, when doing this use a COPY statement to place an environment file at `/etc/default/kazoo`. You can also specify an environment file when running the container using the `--env-file` argument to point to an environment file with all arguments or by adding individual `-e` arguments to `docker run`, one for each argument. In kubernetes you would do specify the environment configuration using the `env` array in the deployment manifest.  It's a reccomendation to keep configuration in kubernetes configmap manifests, and any kind of secrets in kubernetes secret manifests, and then reference them in your env array using the downward api.

* `KAZOO_APPS`: value provided is a comma delimited list that is exported and passed directly to the erlang vm where kazoo will detect it's presence and use that list as the default list of apps to autostart. String, defaults to `blackhole,callflow,cdr,conference,crossbar,doodle,ecallmgr,fax,hangups,hotornot,konami,jonny5,media_mgr,milliwatt,omnipresence,pivot,registrar,reorder,stepswitch,sysconf,teletype,trunkstore,webhooks`.

* `ERLANG_VM`: value provided has `_app` appended and is supplied as the `-s` argument in vm.args and also used as is as the erlang node name, String, defaults to `kazoo_apps`.

* `ERLANG_THREADS`: value provided is supplied as the `+A` argument in vm.args. Integer, defaults to `64`.

* `ERLANG_COOKIE`: value provided is written to `~/.erlang.cookie` by the `write-erlang-cookie` script in the entrypoint. String, defaults to `insecure-cookie`.

* `KAZOO_LOG_LEVEL`: value provided is lowercased and supplied as the value for the console log level in the log section of `config.ini`  String, defaults to `info`

* `KAZOO_LOG_COLOR`: value provided is supplied as the value to the `colored` tuple in `sys.config`.  Boolean, defaults to `true`

* `KAZOO_SASL_ERRLOG_TYPE`: value provided is supplied as the value to `-sasl errlog_type` in `vm.args`. String, defaults to `error`, possible values include: error, progress, all.

* `KAZOO_SASL_ERROR_LOGGER`: value provided is supplied as the value to `-sasl sasl_error_logger` in `vm.args`.  String, defaults to `tty`.  This shouldn't be changed for any good reason when running inside docker and is provided for testing purposes only.

* `REGION`: value provided is interpolated with `DATACENTER` as such `${REGION}-${DATACENTER}` and stored in `KAZOO_ZONE`.  See `KAZOO_ZONE`.  String, defaults to local.

* `DATACENTER`: value provided is interpolated with `REGION` as such `${REGION}-${DATACENTER}` and stored in `KAZOO_ZONE`.  See `KAZOO_ZONE`.  String, defaults to dev.

* `KAZOO_ZONE`: if provided, interpolation of `DATACENTER` and `REGION` is ignored and the value of `KAZOO_ZONE` is used directly, most useful for localized testing and dev environments where ZONE's dont' really matter.  Used as the value for the `[zone]` section and `zone` attribute in other sections of `config.ini`.  String, defaults to the interpolation described above.  Zone's are not behavior as expected in 4.0.

* `COUCHDB_HOST`: value provided will be the hostname or ip address of the load balancer to reach bigcouch or couchdb through and is used in the `[bigcouch]` section of `config.ini`.  String, defaults to `couchdb-bal`

* `COUCHDB_DATA_PORT`: value provided will be the port number supplied to the `port` key in the `[bigcouch]` section of `config.ini`.  String, defaults to `5984`

* `COUCHDB_ADMIN_PORT`: value provided will be the port number supplied to the `admin_port` key in the `[bigcouch]` section of `config.ini`.  String, defaults to `5986`

* `COUCHDB_COMPACT_AUTOMATICALLY`: value provided is supplied as the `compact_automatically` key in the `[bigcouch]` section of `config.ini`.  Boolean, defaults to `true`.

* `COUCHDB_USER`: value provided will be supplied as the `username` key in the `[bigcouch]` section of `config.ini`.  String, defaults to `admin`

* `COUCHDB_PASS`: value provided will be supplied as the `password` key in the `[bigcouch]` section of `config.ini`.  String, defaults to `secret`

* `RABBITMQ_USER`: value provided is interpolated as such `"amqp://user:pass@host:5672"` and supplied to both `uri` keys in the `[amqp]` section of `config.ini`.  String, defaults to `guest`.

* `RABBITMQ_PASS`: value provided is interpolated as such `"amqp://user:pass@host:5672"` and supplied to both `uri` keys in the `[amqp]` section of `config.ini`.  String, defaults to `guest`.

* `RABBITMQ_HOST_A`: value provided is interpolated as such `"amqp://user:pass@host:5672"` and supplied to the first `uri` key in the `[amqp]` section of `config.ini`.  String, defaults to `rabbitmq-alpha`.

* `RABBITMQ_BETA`: value provided is interpolated as such `"amqp://user:pass@host:5672"` and supplied to the second `uri` key in the `[amqp]` section of `config.ini`.  String, defaults to `rabbitmq-beta`.

* `KUBERNETES_HOSTNAME_FIX`: value provided determines whether or not the kubernetes hostname fix is applied.  Boolean, defaults to `false`. See issues for more details.

## Extra tools

There is a binary called [kazootool](kazootool).  It contains the useful functions such as remote_console, upgrade, etc found in the original kazoo service file.  Since using service files in a docker container is a largely bad idea, I've extracted the useful functions and adapted them to work in the container environment.  Check it out

## Instructions

With kazoo 4.0, ecallmgr is now a kapp, so it's no longer necessary to run seperate ecallmgr and kazoo_apps virtual machines unless you want to.

The virtual machine to boot by default is provided as `ERLANG_VM` in the environment, defaulting to `kazoo_apps`. See Run Environment above for more details.

### Makefile convenience rules

If building and running locally for quick testing, feel free to use the convenience targets in the Makefile.

`make build`: builds the image locally and tags it.

`make rebuild`: builds the image locally bypassing the local cache and tags it.

`make run`: bypasses the entrypoint script and opens up a shell directly to the container.

`make launch`: launch under docker locally using the latest build version and default docker network.

`make launch-net`: launch under docker locally using the latest version and the docker network: `local`.  You can create this network if it doesn't exist with `make create-network`.

`make launch-deps`: Starts up local rabbitmq and couchdb servers for local testing. (requires the docker-couchdb and docker-rabbitmq projects and makefiles to both be built and also be reachable as sibling directories)

`make kill-deps`: Kills off local rabbitmq and couchdb servers for local testing. (requires the docker-couchdb and docker-rabbitmq projects and makefiles to both be built and also be reachable as sibling directories)

`make logsf`: Tail the logs of the kazoo docker container you just launched

`make shell`: Exec's into the kazoo container you just launched with a bash shell

`make kill`: does a docker kill to the container

`make stop`: does a docker kill to the container

`make rm`: removes the stopped container

`make rmi`: Removes the image from your local docker images repo.

`make rmf`: stops the running container and then removes the stopped container.

`make create-network`: Creates the docker network: local for local testing of multiple components of kazoo in an isolated network.  You need to run this before using the rules that specify a net alias or network.

`make init-account`: Exec's into the container and uses sup to create the initial master account using static local testing credentials.

`make load-media`: Exec's into the container and uses sup to load the default media into couchdb.

`make init-apps`: Exec's into the container and uses sup to init the monster apps.

*There are way more convenience targets in the Makefile, be sure to check it out.*

### Running under docker using docker hub prebuilt image

All of our docker-* repos in github have automatic build pipelines setup with docker hub, reachable at [https://hub.docker.com/r/callforamerica/](https://hub.docker.com/r/callforamerica/).

This repo resides at: [https://github.com/sip-li/docker-kazoo/tree/4.0](https://github.com/sip-li/docker-kazoo/tree/4.0) under the branch '4.0'.

This image resides at: [https://hub.docker.com/r/callforamerica/kazoo](https://hub.docker.com/r/callforamerica/kazoo) under the tag `4`, and under docker using the shortform: `callforamerica/kazoo:4`

You can run this docker hub image using the following docker run command:

```bash
docker run -d \
    --name kazoo \
    -h kazoo.local \
    -e "COUCHDB_HOST=bigcouch.local" \
    -e "RABBITMQ_HOST_A=rabbitmq-alpha.local" \
    -e "RABBITMQ_HOST_B=rabbitmq-beta.local" \
    -e "KAZOO_LOG_LEVEL=debug" \
    -p "8000:8000" \
    callforamerica/kazoo:4
```

Please use the Run Environment section above to determine which environment variables you will need to change here to get everything working correctly.

### Running under kubernetes

Edit the manifests under kubernetes/ to best reflect your environment and configuration.

You will need to create a kubernetes secret named `erlang-cookie` including the base64'd erlang-cookie under the key: `cookie` or update the deployment manifest to reflect your own name.  See kubernetes documentation for instructions on how to do this.  You will also need to do something similar to create secrets for the authentiation credentials for both couchdb and rabbitmq, but could temporarily just pass all of these values through the env array.

Create the kubernetes service: `make kube-deploy-service`

Create the kubernetes deployment: `make kube-deploy`

That's literally it


## Issues

### 1. Kazoo 4.0 will only boot error-free using the local zone

Trying my best to figure out what is going on here using the 2600hz forums.

### 2. Kubernetes Pod hostname's do not reflect it's PodIP assigned DNS. 

For certain containers running erlang, it can be extremely convenient for the environments hostname to be resolvable to it's ip address outside of the pod.  The hack I've done to work around this requires root privileges at runtime to add entries to the `/etc/hosts` and /etc/hostname file as both are mounted by kubernetes in the container as the root user at runtime, effectively breaking the ability to set a non root user in the dockerfile.  `USER kazoo` has been commented out in the dockerfile for this reason.  If you are not running in a kubernetes environment and do not plan to take advantage of this feature by providing `KUBERNETES_HOSTNAME_FIX=true` to the environment, you can feel free to inherit from this dockerfile and set USER kazoo, `KUBERNETES_HOSTNAME_FIX` is false by default.

I've fixed this by creating a dummy hostname bash script and place it at the beginning of the path: '/opt/kazoo/bin/hostname-fix'.  In the entrypoint script, if `KUBERNETES_HOSTNAME_FIX` is set, this script is linked at runtime to '/opt/kazoo/bin/hostname', and the environment variable `HOSTNAME` is set correctly, as well as creating entries in /etc/hosts and overwriting /etc/hostname.

If anyone knows of a better way to do this, please submit a pull request with a short explanation of the process you used.


## Todos

Fix Issue 1
