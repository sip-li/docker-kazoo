from invoke import task, call

from . import util


@task(default=True)
def up(ctx, d=False):
    flags = []
    if d:
        flags.append('-d')
    flags = ' '.join(flags)
    ctx.run('docker-compose {} {}'.format('up', flags))


@task(pre=[call(up, d=True)])
def launch(ctx):
    pass


@task
def down(ctx, flags=None):
    flags = ctx['dc']['defaults']['down'] + (flags or [])
    ctx.run('docker-compose {} {}'.format(
        'down', util.flags_to_arg_string(flags)))


@task(pre=[down])
def rmf(ctx):
    ctx.run('docker-compose {} {}'.format('rm', '-v'))


@task
def build(ctx):
    cmd = ['docker-compose', 'build']
    ctx.run(' '.join(cmd))


@task(pre=[rmf, build, up])
def rebuild(ctx):
    pass


@task
def logs(ctx, follow=True):
    flags = '-f' if follow else ''
    ctx.run('docker-compose {} {}'.format('logs', flags))


@task
def shell(ctx, service=None, shell=None):
    service = service or ctx.docker['name']
    shell = shell or ctx.docker['shell']
    ctx.run('docker exec -ti {} {}'.format(service, sh), pty=True)
