from invoke import task


@task(default=True)
def docker(ctx):
    ctx.run('tests/run', pty=True)

@task
def local(ctx):
    ctx.run('tests/run local', pty=True)
