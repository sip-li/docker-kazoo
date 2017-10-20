import os

from invoke import task, Collection

from . import test, dc, kube, hub, sup, db


collections = [test, dc, kube, hub, sup, db]

ns = Collection()
for c in collections:
    ns.add_collection(c)

ns.configure(dict(
    project='kazoo',
    repo='docker-kazoo',
    pwd=os.getcwd(),
    docker=dict(
        user=os.getenv('DOCKER_USER', 'joeblackwaslike'),
        org=os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'telephoneorg')),
        name='kazoo',
        tag='%s/%s:latest' % (
            os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'telephoneorg')), 'kazoo'
        ),
        shell='bash'
    ),
    kube=dict(
        environment='testing'
    ),
    hub=dict(
        images=['kazoo', 'couchdb-data', 'couchdb-data-preset']
    ),
    sup=dict(
        constants=dict(
            language='en-us',
            media_path='/opt/kazoo/media/prompts/en/us',
            monster_apps_path='/var/www/html/monster-ui/app',
            crossbar_uri='http://localhost:8000/v2',
            master_account=dict(
                account='test',
                realm='localhost.localdomain',
                user='admin',
                password='secret'
            ),
            fs_node='freeswitch@freeswitch.local',
            sbc_host='kamailio.valuphone.local'
        )
    )
))
