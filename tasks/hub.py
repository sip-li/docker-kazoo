import os

import requests

from invoke import task


@task(default=True)
def push(ctx):
    org = ctx.docker['org']

    if os.getenv('TRAVIS'):
        login(ctx)
    for name in ctx.hub.images:
        ctx.run('docker push {}'.format(
            '{}/{}'.format(ctx.docker['org'], name, ctx.docker['tag'])
        ))

@task
def login(ctx):
    ctx.run('docker login -u {} -p {}'.format(
        ctx.docker['user'], os.getenv('DOCKER_PASS')
    ))


@task
def update_readme(ctx):
    root = 'https://cloud.docker.com/v2/repositories/'
    url = root + '{0[org]}/{0[name]}/'.format(ctx.docker)
    auth = (ctx.docker['user'], os.getenv('DOCKER_PASS'))

    with open('README.md') as fd:
        payload = dict(
            registry='registry-1.docker.io',
            full_description=fd.read()
        )

    r = requests.patch(url, auth=auth, json=payload)
    if not r.ok:
        print('request:', r.status_code, r.text)
    exit(int(not r.ok))
