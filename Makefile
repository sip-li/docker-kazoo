NS = vp
NAME = kazoo
APP_VERSION = 3.22
IMAGE_VERSION = 2.0
VERSION = $(APP_VERSION)-$(IMAGE_VERSION)
LOCAL_TAG = $(NS)/$(NAME):$(VERSION)

REGISTRY = callforamerica
ORG = vp
REMOTE_TAG = $(REGISTRY)/$(NAME):$(VERSION)

GITHUB_REPO = docker-kazoo
DOCKER_REPO = kazoo
BUILD_BRANCH = master


.PHONY: all build test release shell run start stop rm rmi default

all: build

checkout:
	@git checkout $(BUILD_BRANCH)

build:
	@docker build -t $(LOCAL_TAG) --rm .
	$(MAKE) tag

tag:
	@docker tag $(LOCAL_TAG) $(REMOTE_TAG)

rebuild:
	@docker build -t $(LOCAL_TAG) --rm --no-cache .

test:
	@rspec ./tests/*.rb

commit:
	@git add -A .
	@git commit

push:
	@git push origin master

shell:
	@docker exec -ti $(NAME) /bin/bash

shell-ecallmgr:
	@docker exec -ti $(NAME)-ecallmgr /bin/bash

run:
	@docker run -it --rm --name $(NAME) --entrypoint bash $(LOCAL_TAG)

launch-deps:
	-cd ../docker-rabbitmq && make launch-net
	-cd ../docker-bigcouch && make launch-net

launch:
	@docker run -d --name $(NAME) -h $(NAME) -e "ENVIRONMENT=local" -p "8000:8000" $(LOCAL_TAG)

launch-net:
	@docker run -d --name $(NAME) -h whapps.local -e "ENVIRONMENT=local" -e "KAZOO_LOG_LEVEL=debug" -p "8000:8000" --network=local --net-alias=whapps.local $(LOCAL_TAG)

whapps:
	$(MAKE) launch

whapps-net:
	$(MAKE) launch-net

ecallmgr:
	@docker run -d --name $(NAME) -e "KAZOO_APP=ecallmgr" -e "ENVIRONMENT=local" -p "8000:8000" $(LOCAL_TAG)

ecallmgr-net:
	@docker run -d --name $(NAME)-ecallmgr -h ecallmgr.local -e "KAZOO_APP=ecallmgr"  -e "ENVIRONMENT=local" --network=local --net-alias ecallmgr.local $(LOCAL_TAG)

create-network:
	@docker network create -d bridge local

logs:
	@docker logs $(NAME)

logsf-whapps:
	@docker logs -f $(NAME)

logsf-ecallmgr:
	@docker logs -f $(NAME)-ecallmgr

logsf:
	$(MAKE) logsf-whapps

start:
	@docker start $(NAME)

kill:
	@docker kill $(NAME)

kill-ecallmgr:
	@docker kill $(NAME)-ecallmgr

stop:
	@docker stop $(NAME)

stop-ecallmgr:
	@docker stop $(NAME)-callmgr

rm:
	@docker rm $(NAME)

rm-ecallmgr:
	@docker rm $(NAME)-ecallmgr

rmi:
	@docker rmi $(LOCAL_TAG)
	@docker rmi $(REMOTE_TAG)

kube-deploy-whapps:
	@kubectl create -f kubernetes/whapps-deployment.yaml --record

kube-deploy-edit-whapps:
	@kubectl edit deployment/whapps
	$(NAME) kube-rollout-status

kube-deploy-rollback-whapps:
	@kubectl rollout undo deployment/whapps

kube-rollout-status-whapps:
	@kubectl rollout status deployment/whapps

kube-rollout-history-whapps:
	@kubectl rollout history deployment/whapps

kube-delete-deployment-whapps:
	@kubectl delete deployment/whapps

kube-deploy-service-whapps:
	@kubectl create -f kubernetes/whapps-service.yaml

kube-delete-service-whapps:
	@kubectl delete svc whapps

kube-replace-service-whapps:
	@kubectl replace -f kubernetes/whapps-service.yaml

kube-deploy-ecallmgr:
	@kubectl create -f kubernetes/ecallmgr-deployment.yaml --record

kube-deploy-edit:
	@kubectl edit deployment/ecallmgr
	$(NAME) kube-rollout-status

kube-deploy-rollback:
	@kubectl rollout undo deployment/ecallmgr

kube-rollout-status:
	@kubectl rollout status deployment/ecallmgr

kube-rollout-history:
	@kubectl rollout history deployment/ecallmgr

kube-delete-deployment:
	@kubectl delete deployment/ecallmgr

kube-deploy-service:
	@kubectl create -f kubernetes/ecallmgr-service.yaml

kube-delete-service:
	@kubectl delete svc ecallmgr

kube-replace-service:
	@kubectl replace -f kubernetes/ecallmgr-service.yaml	

default: build