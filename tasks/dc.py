from invoke import task, call


DOCKER_COMPOSE_FILES = ['docker-compose.yaml']
DOCKER_COMPOSE_DEFAULTS = dict(
    up=['abort-on-container-exit', 'no-build'],
    down=['volumes']
)


def flags_to_arg_string(flags):
    return ' '.join(['--{}'.format(flag) for flag in flags])


@task(default=True)
def up(ctx, d=False):
    args = []
    if d:
        args.append('-d')
    args = ' '.join(args)
    ctx.run('docker-compose {} {}'.format('up', args))


@task(pre=[call(up, d=True)])
def launch(ctx):
    pass


@task
def down(ctx, flags=None):
    flags = DOCKER_COMPOSE_DEFAULTS['down'] + (flags or [])
    ctx.run('docker-compose {} {}'.format('down', flags_to_arg_string(flags)))


@task(pre=[down])
def rmf(ctx):
    ctx.run('docker-compose {} {}'.format('rm', '-v'))


@task
def build(ctx, rc=False):
    cmd = ['docker-compose']
    if rc:
        cmd.append('-f docker-compose-rc-test.yaml')
    cmd.append('build')
    ctx.run(' '.join(cmd))


@task(pre=[rmf, build, up])
def rebuild(ctx):
    pass


@task
def logs(ctx, follow=True):
    flags = '-f' if follow else ''
    ctx.run('docker-compose {} {}'.format('logs', flags))


@task
def shell(ctx, service=None, sh=None):
    service = service or ctx.docker.name
    sh = sh or ctx.docker.shell
    ctx.run('docker exec -ti {} {}'.format(service, sh), pty=True)
