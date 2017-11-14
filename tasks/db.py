import time

from invoke import task


@task(default=True)
def archive(ctx):
    # ctx.run('docker-compose -f {} up -d'.format(ctx.db['compose_file']))
    # time.sleep(ctx.db['sleep_mins'] * 60)
    ctx.run(
        'docker exec -ti kazoo sup kapps_maintenance refresh system_schemas',
        pty=True)
    time.sleep(30)
    ctx.run(
        'docker exec -ti couchdb tar -czvf {} '
        '-C /volumes/couchdb data'.format(ctx.db['export_file']),
        pty=True
    )
    ctx.run(
        'docker cp couchdb:/opt/couchdb/{} '
        'images/couchdb-data'.format(ctx.db['export_file']),
        pty=True
    )
    ctx.run(
        'docker-compose -f {} -v down'.format(ctx.db['export_file']), pty=True)
    ctx.run('docker-compose build couchdb-data', pty=True)
