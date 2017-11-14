import os

from invoke import task

from . import util


@task(default=True)
def tag_build(ctx):
    current_image = ctx.docker['image']
    build_image = util.image_name(
        ctx, 'build-{}'.format(os.getenv('TRAVIS_BUILD_NUMBER', '0')))
    latest_image = util.image_name(ctx, 'latest')

    print('tagging {} as {}'.format(current_image, build_image))
    ctx.run('docker tag {} {}'.format(current_image, build_image))

    if os.getenv('TRAVIS_PULL_REQUEST') == 'false':
        print('tagging {} as {}'.format(current_image, latest_image))
        ctx.run('docker tag {} {}'.format(current_image, latest_image))
