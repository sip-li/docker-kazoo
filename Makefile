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

kill-deps:
	-cd ../docker-rabbitmq && make kill && make rm
	-cd ../docker-bigcouch && make kill && make rm

launch:
	@docker run -d --name $(NAME) -h $(NAME) -e "ENVIRONMENT=local" -p "8000:8000" $(LOCAL_TAG)

launch-net:
	@docker run -d --name $(NAME) -h whapps.local -e "BIGCOUCH_HOST=bigcouch.local" -e "KAZOO_LOG_LEVEL=debug" -p "8000:8000" --network=local --net-alias=whapps.local $(LOCAL_TAG)

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

init-account:
	@docker exec $(NAME) sup crossbar_maintenance create_account valuphone localhost admin kazootest

init-apps:
	@docker exec $(NAME) sup crossbar_maintenance init_apps /var/www/html/monster-ui/apps http://localhost:8000/v2

get-master-account:
	@docker exec $(NAME) sup crossbar_maintenance find_account_by_name valuphone

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

kube-deploy-service:
	@$(MAKE) kube-deploy-service-whapps
	@$(MAKE) kube-deploy-service-ecallmgr

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

kube-apply-service-whapps:
	@kubectl apply -f kubernetes/whapps-service.yaml

kube-deploy-ecallmgr:
	@kubectl create -f kubernetes/ecallmgr-deployment.yaml --record

kube-deploy-edit-ecallmgr:
	@kubectl edit deployment/ecallmgr
	$(NAME) kube-rollout-status

kube-deploy-rollback-ecallmgr:
	@kubectl rollout undo deployment/ecallmgr

kube-rollout-status-ecallmgr:
	@kubectl rollout status deployment/ecallmgr

kube-rollout-history-ecallmgr:
	@kubectl rollout history deployment/ecallmgr

kube-delete-deployment-ecallmgr:
	@kubectl delete deployment/ecallmgr

kube-deploy-service-ecallmgr:
	@kubectl create -f kubernetes/ecallmgr-service.yaml

kube-delete-service-ecallmgr:
	@kubectl delete svc ecallmgr

kube-apply-service-ecallmgr:
	@kubectl apply -f kubernetes/ecallmgr-service.yaml	

kube-logsf-whapps:
	@kubectl logs -f $(shell kubectl get po | grep whapps | cut -d' ' -f1)

kube-logsft-whapps:
	@kubectl logs -f --tail=25 $(shell kubectl get po | grep whapps | cut -d' ' -f1)

kube-shell-whapps:
	@kubectl exec -ti $(shell kubectl get po | grep whapps | cut -d' ' -f1) -- bash

kube-logsf-ecallmgr:
	@kubectl logs -f $(shell kubectl get po | grep ecallmgr | cut -d' ' -f1)

kube-logsft-ecallmgr:
	@kubectl logs -f --tail=25 $(shell kubectl get po | grep ecallmgr | cut -d' ' -f1)

kube-shell-ecallmgr:
	@kubectl exec -ti $(shell kubectl get po | grep ecallmgr | cut -d' ' -f1) -- bash

whistle-maint-nodes:
	kubectl exec $(shell kubectl get po | grep whapps | cut -d' ' -f1) -- sup -h "$$(hostname)" whistle_maintenance nodes

default: build