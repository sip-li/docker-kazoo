NS = vp
NAME = kazoo
APP_VERSION = 4.0
IMAGE_VERSION = 2.0
VERSION = $(APP_VERSION)-$(IMAGE_VERSION)
LOCAL_TAG = $(NS)/$(NAME):$(VERSION)

REGISTRY = callforamerica
ORG = vp
REMOTE_TAG = $(REGISTRY)/$(NAME):$(VERSION)

GITHUB_REPO = docker-kazoo
DOCKER_REPO = kazoo
BUILD_BRANCH = master

PORT_ARGS = -p "5555:5555" -p "8000:8000" -p "19025:19025" -p "24517:24517"
VOLUME_ARGS = -v "$(PWD)/export:/host"
ENV_ARGS = --env-file default.env
SHELL = bash -l

kamip = $(shell docker inspect -f '{{.NetworkSettings.Networks.local.IPAddress}}' kamailio)

-include ../Makefile.inc

.PHONY: all build test release shell run start stop rm rmi default

all: build

checkout:
	@git checkout $(BUILD_BRANCH)

build:
	@docker build -t $(LOCAL_TAG) --force-rm .
	@$(MAKE) tag
	@$(MAKE) dclean

tag:
	@docker tag $(LOCAL_TAG) $(REMOTE_TAG)

rebuild:
	@docker build -t $(LOCAL_TAG) --force-rm --no-cache .
	@$(MAKE) tag
	@$(MAKE) dclean

test:
	@rspec ./tests/*.rb

commit:
	@git add -A .
	@git commit

push:
	@git push origin master

shell:
	@docker exec -ti $(NAME) $(SHELL)

launch-deps:
	@-cd ../docker-rabbitmq && make launch-as-dep
	@-cd ../docker-couchdb && make launch-as-dep

rmf-deps:
	@-cd ../docker-rabbitmq && make rmf-as-dep
	@-cd ../docker-couchdb && make rmf-as-dep

run:
	@docker run -it --rm --name $(NAME) $(LOCAL_TAG) $(SHELL)

launch:
	@docker run -d --name $(NAME) -h $(NAME).local $(ENV_ARGS) $(PORT_ARGS) $(VOLUME_ARGS) $(LOCAL_TAG)

launch-net:
	@docker run -d --name $(NAME) -h $(NAME).local $(ENV_ARGS) $(PORT_ARGS) $(VOLUME_ARGS) --network=local --net-alias=$(NAME).local $(LOCAL_TAG)

launch-dev:
	@$(MAKE) launch-net

rmf-dev:
	@$(MAKE) rmf

launch-as-dep:
	@$(MAKE) launch-net

rmf-as-dep:
	@$(MAKE) rmf

create-network:
	@docker network create -d bridge local

init-account:
	@docker exec $(NAME) sup crossbar_maintenance create_account test localhost admin kazootest

load-media:
	@docker exec $(NAME) sup kazoo_media_maintenance import_prompts /opt/kazoo/media/prompts/en/us en-us

init-apps:
	@docker exec $(NAME) sup crossbar_maintenance init_apps /var/www/html/monster-ui/apps http://localhost:8000/v2

add-fs-node:
	@docker exec $(NAME) sup ecallmgr_maintenance add_fs_node freeswitch@freeswitch.local

allow-sbc:
	@./allow-sbc.sh dev

get-master-account:
	@docker exec $(NAME) sup crossbar_maintenance find_account_by_name test

logs:
	@docker logs $(NAME)

logsf:
	@docker logs -f $(NAME)

start:
	@docker start $(NAME)

kill:
	@docker kill $(NAME)

stop:
	@docker stop $(NAME)

rm:
	@docker rm $(NAME)

rmi:
	@docker rmi $(LOCAL_TAG)
	@docker rmi $(REMOTE_TAG)

rmf:
	@docker rm -f $(NAME)

kube-deploy-service:
	@kubectl create -f kubernetes/$(NAME)-service.yaml

kube-deploy:
	@kubectl create -f kubernetes/$(NAME)-deployment.yaml --record

kube-deploy-edit:
	@kubectl edit deployment/$(NAME)
	@$(NAME) kube-rollout-status

kube-deploy-rollback:
	@kubectl rollout undo deployment/$(NAME)

kube-rollout-status:
	@kubectl rollout status deployment/$(NAME)

kube-rollout-history:
	@kubectl rollout history deployment/$(NAME)

kube-delete-deployment:
	@kubectl delete deployment/$(NAME)

kube-delete-service:
	@kubectl delete svc $(NAME)

kube-apply-service:
	@kubectl apply -f kubernetes/$(NAME)-service.yaml

kube-logsf:
	@kubectl logs -f $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1)

kube-logsft:
	@kubectl logs -f --tail=25 $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1)

kube-shell:
	@kubectl exec -ti $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1) -- bash

# kube-init-account:
# 	@docker exec $(NAME) sup crossbar_maintenance create_account test localhost admin kazootest

# kube-load-media:
# 	@docker exec $(NAME) sup kazoo_media_maintenance import_prompts /opt/kazoo/media/prompts/en/us en-us

# kube-init-apps:
# 	@docker exec $(NAME) sup crossbar_maintenance init_apps /var/www/html/monster-ui/apps http://localhost:8000/v2

# kube-add-fs-node:
# 	@docker exec $(NAME) sup ecallmgr_maintenance add_fs_node freeswitch@freeswitch.local

kube-allow-sbc:
	@./allow-sbc.sh kube 

default: build