#!/bin/bash
set -x
set -e

ETCD_VER=v3.3.18
names=(1 2 3)
ips=(192.168.1.2 192.168.1.3 192.168.1.4)
token="k8setcd2020"
namesLen=${#names[*]}
ipsLen=${#ips[*]}
if [[ ${namesLen} != ${ipsLen} ]];then
        exit -1
fi

function downloadETCD(){

	# choose either URL
	GOOGLE_URL=https://storage.googleapis.com/etcd
	GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
	DOWNLOAD_URL=${GITHUB_URL}
	
	rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
	rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test
	
	curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
	tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
	rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
	
	/tmp/etcd-download-test/etcd --version
	/tmp/etcd-download-test/etcdctl version

}

function checkSSH(){
    set +x
    for i in "${!ips[@]}"; 
    do 
        ip=${ips[$i]}
        ssh $ip hostname
    done
    set -x
}

function clusterStr() {
        separator=","
        for i in "${!names[@]}"; 
        do 
            if [[ $(($i+1)) == $namesLen ]];then
                    separator=""
            fi
            tmpStr="etcd${names[$i]}=http://${ips[$i]}:2380${separator}"
            cluster_str+=${tmpStr}
        done
        echo $cluster_str
}

function etcdService(){
cat > etcd${ip}.service <<EOF
[Unit]
Description=MZ k8s Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/data/etcd$name/
Type=notify
ExecStart=/usr/bin/etcd \\
--name etcd${name} \\
--data-dir /data/etcd \\
--listen-peer-urls http://${ip}:2380 \\
--listen-client-urls http://${ip}:2379,http://${ip}:4001,http://127.0.0.1:2379 \\
--initial-advertise-peer-urls http://${ip}:2380 \\
--initial-cluster ${cluster_str}  \\
--initial-cluster-state new \\
--initial-cluster-token ${token} \\
--advertise-client-urls http://${ip}:2379,http://${ip}:4001

Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
}

function main(){
    downloadETCD
    cluster_str=$(clusterStr)
    
    for i in "${!names[@]}"; 
    do 
        name=${names[$i]}
        ip=${ips[$i]}
        etcdService
        scp /tmp/etcd-download-test/etcd $ip:/usr/bin/etcd
        scp /tmp/etcd-download-test/etcdctl $ip:/usr/bin/etcdctl
        scp etcd${ip}.service $ip:/usr/lib/systemd/system/etcd.service
        ssh $ip systemctl enable etcd.service
        ssh $ip systemctl start etcd.service
        ssh $ip systemctl status etcd.service
    done
}
checkSSH
main

#cluster_str=$(clusterStr)
#
#for i in "${!names[@]}"; 
#do 
#    name=${names[$i]}
#    ip=${ips[$i]}
#    etcdService
#done

#for i in {1..3}
#do
#        ip=${ip${i}}
#        name=${name${i}}
#        etcdService
#done
