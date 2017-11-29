from invoke import task


@task(default=True)
def deploy(ctx, environment=None):
    ctx.run('kubectl apply -f kubernetes/%s' % (
        environment or ctx.kube.environment
    ))


@task
def delete(ctx, environment=None):
    ctx.run('kubectl delete -f kubernetes/%s' % (
        environment or ctx.kube.environment
    ))


@task(pre=[delete, deploy])
def redeploy(ctx, environment=None):
    pass
