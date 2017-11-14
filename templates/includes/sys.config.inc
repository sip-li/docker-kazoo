---
target: /config/sys.config
---

{%- set config_map = env.get('CONFIG_MAP', 'kazoo') %}
{% set config = kube.get('configmap', config_map).data -%}

[
    {lager, [
        {handlers, [
            {lager_console_backend, info}
        ]},
    {colored, {{ config['kazoo.log.color'] }}},
    {colors, [
        {debug,     "\e[0;38m" },
        {info,      "\e[1;32m" },
        {notice,    "\e[1;36m" },
        {warning,   "\e[1;33m" },
        {error,     "\e[1;31m" },
        {critical,  "\e[1;35m" },
        {alert,     "\e[1;44m" },
        {emergency, "\e[1;41m" }
    ]},
    {error_logger_hwm, 500}
    ]}
].
