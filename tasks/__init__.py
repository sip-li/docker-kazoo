import os

from invoke import task, Collection

from . import test, kube


collections = [test, kube]

ns = Collection()
for c in collections:
    ns.add_collection(c)

ns.configure(dict(
    project='kazoo',
    repo='docker-kazoo',
    pwd=os.getcwd(),
    docker=dict(
        user=os.getenv('DOCKER_USER'),
        tag='%s/%s:latest' % (os.getenv('DOCKER_USER'), 'kazoo')
    ),
    kube=dict(
        environment='testing'
    )
))
