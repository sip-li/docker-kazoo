import sys

from invoke import Collection, task

from . import admin, ci, dc, hub, kube, test, tmpl, util
from . import db, sup


config = util.build_config('config.yaml')
util.export_docker_tag()

namespace = Collection()
for mod in config['modules']:
    namespace.add_collection(globals()[mod])

namespace.configure(config)
