import os

from invoke import task


def execute_test(ctx, command, args=None):
    command = [command, ctx.docker['name']]
    if args:
        command.append(args)

    ctx.run('docker pull {}'.format(ctx.test['image']))
    ctx.run(
        'docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock '
        '-v {}:/repo -v /tmp:/tmp -e DOCKER_TAG {} dcgoss {}'.format(
            ctx.pwd, ctx.test['image'], ' '.join(command)
    ), pty=True)


@task(default=True)
def run(ctx, command=None):
    return execute_test(ctx, 'run', command)


@task
def edit(ctx, command=None):
    return execute_test(ctx, 'edit', command)
