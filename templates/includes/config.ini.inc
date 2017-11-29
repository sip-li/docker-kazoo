---
target: /config/config.ini
---

{%- set config_map = env.get('CONFIG_MAP', 'kazoo') -%}
{%- set config = kube.get('configmap', config_map).data -%}
{%- set rabbitmq = kube.get('secret', 'rabbitmq').data -%}
{%- set erlang = kube.get('secret', 'erlang').data -%}
{%- set couchdb = kube.get('secret', 'couchdb').data -%}

{%- set zone = '{}-{}'.format(
    config.get('kazoo.country', 'us'), config.get('kazoo.region', 'east')
    ) -%}
{%- set amqp_uri = 'amqp://{}:{}@{}:5672'.format(
    rabbitmq.get('user', 'guest'),
    rabbitmq.get('pass', 'guest'),
    config.get('rabbitmq.host', 'rabbitmq')
    ) -%}
{%- set fqdn = shell('hostname -f') -%}

[zone]
name = {{ zone }}
amqp_uri = "{{ amqp_uri }}"

[bigcouch]
ip = "{{ config.get('couchdb.host', 'couchdb-lb') }}"
port = {{ config.get('couchdb.port', '5984') }}
admin_port = {{ config.get('couchdb.admin-port', '5986') }}
cookie = {{ erlang.get('cookie', 'insecure-cookie') }}
compact_automatically = true
{% if couchdb.get('user') and couchdb.get('pass') %}
username = "{{ couchdb.get('user', 'admin') }}"
password = "{{ couchdb.get('pass', 'secret') }}"
{% endif %}

[kazoo_apps]
host = {{ fqdn }}
cookie = {{ erlang.get('cookie', 'insecure-cookie') }}
zone = {{ zone }}

[log]
console = {{ config.get('kazoo.log.level', 'info') }}
