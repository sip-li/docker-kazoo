# Helpers

function get-name {
    local name=$(basename $PWD)
    if echo "$name" | grep -q docker; then
        name=$(echo "$name" | cut -d'-' -f2)
    fi
    echo "$name"
}

function get-docker-org {
    if [[ ! -z $DOCKER_ORG ]]; then
        echo "$DOCKER_ORG"
    elif [[ ! -z $DOCKER_USER ]]; then
        echo "$DOCKER_USER"
    else
        return 1
    fi
}

function get-github-org {
    if [[ ! -z $GITHUB_ORG ]]; then
        echo "$GITHUB_ORG"
    elif [[ ! -z $GITHUB_USER ]]; then
        echo "$GITHUB_USER"
    else
        return 1
    fi
}

# Creates a stable branch identifier when executing CI on pull requests.
function get-branch {
    if [[ ! -z $TRAVIS ]]; then
        if [[ $TRAVIS_PULL_REQUEST == 'false' ]]; then
            export BRANCH=$TRAVIS_BRANCH
        else
            export BRANCH=$TRAVIS_PULL_REQUEST_BRANCH
        fi
    fi
    printf "${BRANCH:=$(basename $(git status | head -1 | awk '{print $NF}'))}"
}

function get-docker-tag {
    local tag
    local branch=$(get-branch)
    if [[ $branch == 'master' ]]; then
        tag='latest'
    else
        tag=$branch
    fi
    # printf "${tag:-latest}"
    printf 'latest'
}

function get-docker-user {
    if [[ ! -z $DOCKER_USER ]]; then
        printf "$DOCKER_USER"
    else
        return 1
    fi
}

function get-docker-image {
    local org=$(get-docker-org)
    local name=$(get-name)
    local tag=$(get-docker-tag)
    printf "$org/$name:$tag"
}

# Actions

function tag {
    if [[ -z $1 ]]; then
        printf 'Usage: %s <new-tag>\n' $0
    fi
    local new_tag="$1"
    local org=$(get-docker-org)
    local name=$(get-name)
    local image=$(get-docker-image)
    docker tag $image $org/$name:$new_tag
}

function hub-push {
    local org=$(get-docker-org)
    local name=$(get-name)
    local user=$(get-docker-user)
    local image=$(get-docker-image)
    if [[ -z $user || -z $DOCKER_PASS ]]; then
        printf 'DOCKER_USER/PASS environment variable not set\n'
        return 1
    fi
    docker login -u $user -p $DOCKER_PASS
    docker push $image
}

# function github-tag {
#     if [[ -z $BUILD_TOKEN ]]; then
#         printf 'BUILD_TOKEN not set.\n'
#         return 1
#     fi
#     local name=$(get-name)
#     local tag=$(get-tag)
#     local user=$(get-docker-user)
#     curl -s -X POST -H "Content-Type: application/json" \
#     	--data '{"docker_tag": "$tag"}' \
#     	https://registry.hub.docker.com/u/$user/$name/trigger/$BUILD_TOKEN/
# }

function clone-deps {
    local org=$(get-github-org)
    local dep
    if [[ ! -z "$@" ]]; then
        printf "Cloning deps: $@\n"
        for dep in "$@"; do
            pushd ..
            git clone https://github.com/$org/docker-${dep}
            popd
        done
    fi
}

function pull-deps {
    local org=$(get-docker-org)
    local dep
    if [[ ! -z "$@" ]]; then
        printf "Pulling deps: $@\n"
        for dep in "$@"; do
            docker pull $org/$dep
        done
    fi
}

function ci-tag-build {
    if [[ -z $TRAVIS ]]; then
        printf 'Not in CI environment!\n'
        return 1
    fi
    tag ${TRAVIS_COMMIT::6}
    tag travis-$TRAVIS_BUILD_NUMBER
}

function rebuild-dependent {
    local repo="$1"
    local org=$(get-github-org)
    if [[ -z $repo ]]; then
        printf 'you need to provide the child repo as argument 1\n'
        return 1
    fi
    local build_num=$(curl -s "https://api.travis-ci.org/repos/$org/$repo/builds" | grep -o '^\[{"id":[0-9]*,' | grep -o '[0-9]' | tr -d '\n')
    curl -X POST https://api.travis-ci.org/builds/$build_num/restart --header "Authorization: token $GITHUB_TOKEN"
}

function rebuild-dependents {
    if [[ -z $CHILD_REPOS ]]; then
        printf "CHILD_REPOS not defined in environment, can't rebuild 1\n"
        return 1
    elif [[ -z $GITHUB_TOKEN ]]; then
        printf 'you need to provide the GITHUB_TOKEN environment variable.\n'
        return 1
    fi
    for child in ${CHILD_REPOS//,/ }; do
        rebuild-dependent $child
    done
}

function hub-update-readme {
    local file
    if [[ -f README.md ]]; then
        file=README.md
    elif [[ -f README.rst ]]; then
        file=README.rst
    else
        return 0
    fi
    _hub-update-readme $file
}

function _hub-update-readme {
    local file="${1:-README.md}"
    local org=$(get-docker-org)
    local name=$(get-name)
    local tag=$(get-docker-tag)
    local user=$(get-docker-user)
    curl -vX PATCH "https://cloud.docker.com/v2/repositories/$org/$name/" \
        -u "$user:$DOCKER_PASS" \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -d @<(jq -MRcs '{"registry":"registry-1.docker.io","full_description": . }' $file)
}

function hub-trigger {
    if [[ -z $BUILD_TOKEN ]]; then
        printf 'BUILD_TOKEN not set.\n'
        return 1
    fi
    local name=$(get-name)
    local tag=$(get-docker-tag)
    local org=$(get-docker-org)
    curl -s -X POST -H "Content-Type: application/json" \
    	--data '{"docker_tag": "$tag"}' \
    	https://registry.hub.docker.com/u/$org/$name/trigger/$BUILD_TOKEN/
}


if [[ -f scripts/ci/vars.env ]]; then
    source scripts/ci/vars.env
fi

export ORG=$(get-docker-org)
export NAME=$(get-name)
export BRANCH=$(get-branch)
export TAG=$(get-docker-tag)
export DOCKER_IMAGE=$(get-docker-image)

echo -e "
ORG: $ORG
NAME: $NAME
BRANCH: $BRANCH
TAG: $TAG
DOCKER_USER: $DOCKER_USER
DOCKER_IMAGE: $DOCKER_IMAGE
"
