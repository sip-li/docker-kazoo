import time

from invoke import task

# from . import sup


@task(default=True)
def archive(ctx):
    ctx.run('docker-compose -f docker-compose-couchdb-data.yaml up -d')
    time.sleep(16 * 60)
    ctx.run(
        'docker exec -ti kazoo sup kapps_maintenance refresh system_schemas')
    time.sleep(60)
    ctx.run(
        'docker exec -ti couchdb tar -czvf couchdb-data.tar.gz '
        '-C /volumes/couchdb data',
        pty=True
    )
    ctx.run(
        'docker cp couchdb:/opt/couchdb/couchdb-data.tar.gz '
        'images/couchdb-data/',
        pty=True
    )
