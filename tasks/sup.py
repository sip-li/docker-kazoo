from invoke import task

import subprocess


# helpers
def get_container_ip(name):
    return subprocess.getoutput(
        "docker inspect --format "
        "'{{.NetworkSettings.Networks.dockerkazoo_local.IPAddress}}' " + name
    )


@task(default=True)
def sup(ctx, *args):
    cmd = 'docker exec -ti kazoo sup {}'.format(' '.join(args))
    print(cmd)
    ctx.run(cmd, pty=True)


@task
def create_master_account(ctx):
    c = ctx.sup['constants']['master_account']
    sup(ctx,
        'crossbar_maintenance',
        'create_account',
        c['account'],
        c['realm'],
        c['user'],
        c['password']
    )


@task
def import_prompts(ctx):
    c = ctx.sup['constants']
    sup(ctx,
        'kazoo_media_maintenance',
        'import_prompts',
        c['media_path'],
        c['language']
    )


@task
def init_apps(ctx):
    c = ctx.sup['constants']
    sup(ctx,
        'crossbar_maintenance',
        'init_apps',
        c['monster_apps_path'],
        c['crossbar_uri']
    )


@task
def add_fs_node(ctx):
    c = ctx.sup['constants']
    sup(ctx,
        'ecallmgr_maintenance',
        'add_fs_node',
        c['fs_node']
    )

@task
def allow_sbc(ctx):
    c = ctx.sup['constants']
    kam_ip = get_container_ip('kamailio')
    cidr_range = '.'.join(kam_ip.split('.')[:-1] + ['0']) + '/24'
    sup(ctx,
        'ecallmgr_maintenance',
        'allow_sbc',
        c['sbc_host'],
        cidr_range
    )


@task(pre=[create_master_account, import_prompts, init_apps, add_fs_node, allow_sbc])
def all(ctx):
    pass
