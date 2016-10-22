#!/bin/bash

kamailio_docker_name=kamailio
kamailio_docker_host=kamailio.local

kamailio_kube_query=kamailio

dev
{
    local kamailio_ip=$(docker inspect -f '{{.NetworkSettings.Networks.local.IPAddress}}' $kamailio_docker_name)
    echo "Adding host: $kamailio_docker_host ip: $kamailio_ip to local dev kazoo ..."
    docker exec kazoo sup ecallmgr_maintenance allow_sbc $kamailio_docker_host $kamailio_ip
}

kube
{   local kamailio_pod_name=$(kubectl get po | grep $kamailio_kube_query | awk '{print $1}')
    local kamailio_ip=$(kubectl get po $kamailio_pod_name -o json | jq -r '.status.hostIP')
    local kamailio_host=$(kubectl get po kamailio-1309781464-lgv18 -o json | jq -r '.spec.nodeSelector."kubernetes.io/hostname"')
    echo "Adding host: $kamailio_host ip: $kamailio_ip to pod: $kamailio_pod_name @ remote kubernetes cluster ..."
    kubectl exec $kamailio_pod_name -- sup ecallmgr_maintenance allow_sbc $kamailio_host $kamailio_ip
}

if [[ ! -z $1 ]]
then
    "$@"
else
    echo "usage: $(basename $0) {dev|kube}"
    exit 1
fi
