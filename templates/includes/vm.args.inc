---
target: /config/vm.args
---
{% set config_map = env.get('CONFIG_MAP', 'kazoo') %}
{% set config = kube.get('configmap', config_map).data -%}

# Turn off the sasl error logger
-sasl sasl_error_logger false

# Boot kazoo 4.0.0 release
-boot /opt/kazoo/releases/4.0.0/kazoo

# Loading mode
-mode interactive

# Use the following erlang hostname
{% if config.get('erlang.hostname') == 'long' %}
-name kazoo
{% else %}
-sname kazoo
{% endif %}

# Use the following sys.config
-config /config/sys.config

# Set erlang distribution to use 11500-11999 ports instead of random
# predictibility has value here
-kernel inet_dist_listen_min 11500 inet_dist_listen_max 11999

# Use kernel poll functionality if supported by emulator
+K true

# Maximum number of processes
+P {{ config.get('erlang.processes', shell('nproc') * 3200) }}

# Start a pool of asynchronous IO threads
+A {{ config.get('erlang.threads', shell('nproc') * 16) }}

# Treat error_logger:warning_msg/2 as warnings instead of errors (default)
+W w

# Comment this line out if you want the Erlang shell
+Bd -noinput

# Erlang VM to boot
-s kazoo_apps_app
