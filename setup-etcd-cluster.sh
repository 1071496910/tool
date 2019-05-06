#!/bin/bash

function net_setup() {

    brctl addbr etcd-cluster
    ip link set dev etcd-cluster up
    
    for i in {1..3}
    do
        ip netns add etcd${i}
        ip link add etcd${i} type veth peer name eth0 netns etcd${i}
        brctl addif etcd-cluster etcd${i}
        ip netns exec etcd${i} ip a a 192.168.1.$(($i+1))/24 dev eth0
        ip netns exec etcd${i} ip link set dev eth0 up
        ip netns exec etcd${i} ip link set dev lo up
        ip link set dev etcd${i} up
    done
}

function net_clean() {
    for i in {1..3}
    do
        ip netns del etcd${i}
        ip link del etcd${i} 
    done
    ip link set dev etcd-cluster down
    brctl delbr etcd-cluster        
}

function cluster_setup(){

    for i in {1..3}
    do
         mkdir -p /data/etcd${i}

         ip netns exec etcd${i} /opt/kubernetes/bin/etcd \
            --name etcd${i} \
            --data-dir /data/etcd${i} \
            --listen-peer-urls http://192.168.1.$((${i}+1)):2380 \
            --listen-client-urls http://192.168.1.$((${i}+1)):2379,http://192.168.1.$((${i}+1)):4001,http://127.0.0.1:2379 \
            --initial-advertise-peer-urls http://192.168.1.$((${i}+1)):2380 \
            --initial-cluster etcd1=http://192.168.1.2:2380,etcd2=http://192.168.1.3:2380,etcd3=http://192.168.1.4:2380 \
            --initial-cluster-state new \
            --initial-cluster-token etcd-cluster \
            --advertise-client-urls http://192.168.1.$((${i}+1)):2379,http://192.168.1.$((${i}+1)):4001 >> /data/etcd${i}/etcd.log 2>&1 &
    done
}

function cluster_clean() {
        pkill etcd
}

case $1 in
        "net-clean")
                net_clean
                ;;
        "net-setup")
                net_setup
                ;;
        "cluster-clean")
                cluster_clean
                ;;
        "cluster-setup")
                cluster_setup
                ;;
        *)
                echo "./setup-etcd-cluster.sh  <[net-clean|net-setup|cluster-clean|cluster-setup]>"
esac


#/opt/kubernetes/bin/etcd \
#        --name etcd0 \
#        --data-dir /data/etcd \
#        --listen-peer-urls http://10.3.135.209:2380 \
#        --listen-client-urls http://10.3.135.209:2379,http://10.3.135.209:4001,http://127.0.0.1:2379 \
#        --initial-advertise-peer-urls http://10.3.135.209:2380 \
#        --initial-cluster etcd0=http://10.3.135.209:2380,etcd1=http://10.3.135.224:2380,etcd2=http://10.3.135.217:2380 \
#        --initial-cluster-state new \
#        --initial-cluster-token etcd-cluster \
#        --advertise-client-urls http://10.3.135.209:2379,http://10.3.135.209:4001
