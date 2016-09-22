# Kazoo v4.0 dockerized with kubernetes fixes and manifests

## Maintainer

Joe Black <joe@valuphone.com>

## Introduction 

The aim of this docker project is to make running kazoo in a dockerized environment easy for everyone and combine all the experience we've learned running kazoo in docker in a way that lowers the barrier of entry to others wanting to run kazoo under docker.  We target both a local docker only environment and a production environment using kubernetes as a cluster manager.  We reccomend the same but also have made the effort to make this flexible enough to be usable under a variety of cluster managers or even none at all.

Pull requests with improvements always welcome.

## Build Environment

Build environment variables are used in the build script as plug in variables that can be set in the Dockerfile to bump version numbers of the various things that are installed during the `docker build` phase.

* `ERLANG_VERSION`: value provided is supplied to kerl and determines the version of erlang that is installed prior to kazoo being built. String, defaults to `18.3`.

* `KAZOO_VERSION`: value provided is used to select the branch to clone from the 2600hz/kazoo repo. String, defaults to `master`.

* `MONSTER_UI_VERSION`: value provided is used to select the branch to clone from the 2600hz/monster-ui repo but also for each of the apps in `MONSTER_APPS`. String, defaults to `master`.

* `NODE_VERSION`: value provided is used as the version of node.js to install. String, defaults to `6`.

* `GOSU_VERSION`: value provided is used as the version of gosu to install. String, defaults to `1.9`.

* `DUMB_INIT_VERSION`: value provided is used as the version of dumb-init to install. String, defaults to `1.1.3`.


## Run Environment

Run environment variables are used in the entrypoint script when rendering configuration templates and sometimes also for affecting the flow of the entrypoint script.  These values can be provided when inheriting from the base dockerfile, or also specified at `docker run` as `-e` arguments, and in kubernetes manifests in the `env` array.

* `ERLANG_VM`: value provided has `_app` appended and is supplied as the `-s` argument in vm.args and also used as is as the erlang node name, defaults to `kazoo_apps`.

* `ERLANG_THREADS`: value provided is supplied as the `+A` argument in vm.args. Integer, defaults to `25`.

* `KAZOO_LOG_LEVEL`: value provided is lowercased and supplied as the value for the console log level in the log section of `config.ini`  String, defaults to `info`

* `KAZOO_LOG_COLOR`: value provided is supplied as the value to the `colored` tuple in `sys.config`.  Boolean, defaults to `true`

* `KAZOO_SASL_ERRLOG_TYPE`: value provided is supplied as the value to `-sasl errlog_type` in `vm.args`. String, defaults to `error`, possible values include: error, progress, all.

* `KAZOO_SASL_ERROR_LOGGER`: value provided is supplied as the value to `-sasl sasl_error_logger` in `vm.args`.  String, defaults to `tty`.  This shouldn't be changed for any good reason when running inside docker and is provided for testing purposes only.

* `DATACENTER`: value provided is interpolated with `REGION` as such `${REGION}-${DATACENTER}` and stored in `KAZOO_ZONE`.  See `KAZOO_ZONE`.  String, defaults to dev.

* `REGION`: value provided is interpolated with `DATACENTER` as such `${REGION}-${DATACENTER}` and stored in `KAZOO_ZONE`.  See `KAZOO_ZONE`.  String, defaults to local.

* `KAZOO_ZONE`: if provided, interpolation of `DATACENTER` and `REGION` is ignored and the value of `KAZOO_ZONE` is used directly, most useful for localized testing and dev environments where ZONE's dont' really matter.  Used as the value for the `[zone]` section and `zone` attribute in other sections of `config.ini`.  String, defaults to the interpolation described above.  Zone's appear to be broken in Kazoo 4.0, see relavent Issue in Issues section.

* `BIGCOUCH_HOST`: value provided will be the hostname or ip address of the load balancer to reach bigcouch or couchdb through and is used in the `[bigcouch]` section of `config.ini`.  String, defaults to `bigcouchbal`

* `BIGCOUCH_DATA_PORT`: value provided will be the port number supplied to the `port` key in the `[bigcouch]` section of `config.ini`.  String, defaults to `5984`

* `BIGCOUCH_ADMIN_PORT`: value provided will be the port number supplied to the `admin_port` key in the `[bigcouch]` section of `config.ini`.  String, defaults to `5986`

* `BIGCOUCH_COMPACT_AUTOMATICALLY`: value provided is supplied as the `compact_automatically` key in the `[bigcouch]` section of `config.ini`.  Boolean, defaults to `true`.

* `KAZOO_AMQP_HOST`: value provided is interpolated as such `"amqp://guest:guest@$KAZOO_AMQP_HOST:5672"` and supplied as the first `uri` key in the `[amqp]` section of `config.ini`.  String, defaults to `rabbitmq-alpha`, and should be either a hostname or ip address.

* `KAZOO_SECONDARY_AMQP_HOST`: value provided is interpolated as such `"amqp://guest:guest@$KAZOO_SECONDARY_AMQP_HOST:5672"` and supplied as the second `uri` key in the `[amqp]` section of `config.ini`.  String, defaults to `rabbitmq-beta`, and should be either a hostname or ip address.

* `KUBERNETES_HOSTNAME_FIX`: value provided determines whether or not the kubernetes hostname fix is applied.  Boolean, defaults to `false`. See issues for more details.


## Instructions

With kazoo 4.0, ecallmgr is now a kapp, so it's no longer necessary to run seperate ecallmgr and kazoo_apps virtual machines.  

The virtual machine to boot by default is provided as `ERLANG_VM` in the environment, see Run Environment above for more details.

### Running locally under docker

If building and running locally for quick testing, feel free to use the convenience targets in the Makefile.

`make launch`: launch under docker locally using the latest build version and default docker network.

`make launch-net`: launch under docker locally using the latest version and the docker network: `local`.  You can create this network if it doesn't exist with `make create-network`.

`make launch-deps`: Starts up local rabbitmq and couchdb servers for local testing. (requires the docker-couchdb and docker-rabbitmq projects to also be reachable as sibling directories)

`make logsf`: Tail the logs of the kazoo docker container you just launched

`make shell`: Exec's into the kazoo container you just launched with a bash shell

`make init-account`: Exec's into the container and uses sup to create the initial master account using static local testing credentials.

`make init-apps`: Exec's into the container and uses sup to init the monster apps.

*There are way more convenience targets in the Makefile, be sure to check it out.*

### Running under docker using docker hub prebuilt image

All of our docker-* repos in github have automatic build pipelines setup with docker hub, reachable at [https://hub.docker.com/r/callforamerica/](https://hub.docker.com/r/callforamerica/).

This image resides at: [https://hub.docker.com/r/callforamerica/kazoo](https://hub.docker.com/r/callforamerica/kazoo) under the tag `4`, and under docker using the shortform: `callforamerica/kazoo:4`

You can run this docker hub image using the following docker run command:

```bash
docker run -d \
    --name kazoo \
    -h kazoo.local \
    -e "BIGCOUCH_HOST=bigcouch.local" \
    -e "RABBITMQ_AMQP_HOST=rabbitmq-alpha" \
    -e "RABBITMQ_SECONDARY_AMQP_HOST=rabbitmq-beta" \
    -e "KAZOO_LOG_LEVEL=debug" \
    -p "8000:8000" \
    callforamerica/kazoo:4
```

Please use the Run Environment section above to determine which environment variables you will need to change here to get everything working correctly.

### Running under kubernetes

Edit the manifests under kubernetes/ to best reflect your environment and configuration.

You will need to create a kubernetes secret named `erlang-cookie` including the base64'd erlang-cookie under the key: `cookie` or update the deployment manifest to reflect your own name.  See kubernetes documentation for instructions on how to do this.

Create the kubernetes service: `make kube-deploy-service`

Create the kubernetes deployment: `make kube-deploy`

That's literally it


## Issues

### 1. Sometimes the build process will exit early due to a remote server error using apt-get

No idea why this happens but it only effects debian, lovely.  Careful consideration will be necessary to make sure building this image doesn't return early.  The build script sets the -e flag to ensure this isn't ignored silently.

### 2. Kazoo 4.0 Seems to break parsing the zone sections and zone attributes of other sections

The first result is that the [zone] section is broken parsing the name attribute, adding in an additional [amqp] section set to defaults, adding a third amqp uri defaulting to localhost, it is quite verbose about this in the logs.

The second result is that any section such as [bigcouch] for instance is broken parsing the zone attribute and the section is entirely ignored.

My suspicions with my limited erlang experience is that the quotes are removed during parsing leaving the values as atoms instead of strings.  I could very well be wrong though.

### 3. Kubernetes Pod hostname's do not reflect it's PodIP assigned DNS. 

For certain containers running erlang, it can be extremely convenient for the environments hostname to be resolvable to it's ip address outside of the pod.  The hack I've done to work around this requires root privileges at runtime to add entries to the `/etc/hosts` and /etc/hostname file as both are mounted by kubernetes in the container as the root user at runtime, effectively breaking the ability to set a non root user in the dockerfile.  `USER kazoo` has been commented out in the dockerfile for this reason.  If you are not running in a kubernetes environment and do not plan to take advantage of this feature by providing `KUBERNETES_HOSTNAME_FIX=true` to the environment, you can feel free to inherit from this dockerfile and set USER kazoo, `KUBERNETES_HOSTNAME_FIX` is false by default.

I've fixed this by creating a dummy hostname bash script and place it at the beginning of the path: '/opt/kazoo/bin/hostname-fix'.  In the entrypoint script, if `KUBERNETES_HOSTNAME_FIX` is set, this script is linked at runtime to '/opt/kazoo/bin/hostname', and the environment variable `HOSTNAME` is set correctly, as well as creating entries in /etc/hosts and overwriting /etc/hostname.

If anyone knows of a better way to do this, please submit a pull request with a short explanation of the process you used.


## Todos

* 1. Better integration with make-release and erlang release system

unsure whether the current entrypoint would write the correct templates when using the result of make-release.

* 2. Do some post build optimization at the end of the build script to remove everything that's not necessary or super useful for debugging later  

Thin out the apt packages, remove files unnecessary in the /opt/kazoo directory to running kazoo, remove unnecessary files in the monster-ui and apps directory to the init_apps process, etc.  Clear any cache's that I might have missed.  This must be done in the same build script because of the way docker's file system works with layers and the union file system abstraction.  Removing files or modifying files in subsequent layers will actually add size to the overall image, even simply changing their permissions will do this.
