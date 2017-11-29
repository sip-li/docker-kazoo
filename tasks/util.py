import os
from os.path import join, abspath, dirname
import copy

import yaml


def get_docker_tag():
    if os.getenv('TRAVIS') == 'true':
        return get_docker_tag_ci()
    else:
        return os.getenv('DOCKER_TAG', 'latest')


def get_docker_tag_ci():
    event_type = os.getenv('TRAVIS_EVENT_TYPE')
    travis_branch = os.getenv('TRAVIS_BRANCH')
    travis_tag = os.getenv('TRAVIS_TAG')
    travis_commit = os.getenv('TRAVIS_COMMIT')
    travis_pr = os.getenv('TRAVIS_PULL_REQUEST')

    if event_type == 'pull_request':
        return '{}-pr-{}'.format(travis_branch, travis_pr)
    elif event_type == 'push':
        if travis_tag == travis_branch:
            return travis_tag
        else:
            return travis_commit[:6]


def image_name(ctx, tag):
    return '{}/{}:{}'.format(ctx.docker['org'], ctx.docker['name'], tag)


def export_docker_tag():
    tag = get_docker_tag()
    os.environ.update(dict(DOCKER_TAG=tag))


def get_docker_org():
    return os.getenv('DOCKER_ORG', os.getenv('DOCKER_USER', 'telephoneorg'))


def flags_to_arg_string(flags):
    return ' '.join(['--{}'.format(flag) for flag in flags])


def deepupdate(target, src):
    target = copy.deepcopy(target)

    for k, v in src.items():
        if type(v) == list:
            if not k in target:
                target[k] = copy.deepcopy(v)
        elif type(v) == dict:
            if not k in target:
                target[k] = copy.deepcopy(v)
            else:
                target[k] = deepupdate(target[k], v)
        else:
            if not k in target:
                target[k] = copy.copy(v)
    return target


def build_config(path='config.yaml'):
    default_mods = ['admin', 'ci', 'dc', 'hub', 'kube', 'test', 'tmpl']
    defaults = dict(
        extras=[],
        project='',
        repo='',
        pwd=os.getcwd(),
        docker=dict(
            user=os.getenv('DOCKER_USER', 'joeblackwaslike'),
            org=get_docker_org(),
            tag=get_docker_tag(),
            shell='bash'
        ),
        dc=dict(
            files=['docker-compose.yaml'],
            defaults=dict(
                up=['abort-on-container-exit', 'no-build'],
                down=['volumes']
            )
        ),
        test=dict(
            image='telephoneorg/dcgoss:latest'
        ),
        kube=dict(
            environment='production'
        ),
        hub=dict(
            images=['']
        ),
        admin=dict(),
        tmpl=dict(
            glob='templates/**/*.j2',
            values=['vars.yaml']
        )
    )

    path = join(abspath(dirname(__file__)), path)
    with open(path) as fd:
        config = yaml.load(fd)

    config = deepupdate(config, defaults)
    config['modules'] = list(set(default_mods + config['extras']))
    config['docker']['name'] = config['project']
    config['docker']['image'] = '{}/{}:{}'.format(
        get_docker_org(), config['project'], get_docker_tag()
    )
    return config
