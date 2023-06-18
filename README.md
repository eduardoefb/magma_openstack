### Deploy magma on kubespray 

#### Requirements:
1) To be able to install magma using this procedure, you first need to install openstack with the following services:
 - nova
 - cinder
 - neutron
 - designator
 - octavia

Refere to the this [guide](https://gitlab.com/eduardoefb/openstack-ubuntu/-/tree/victoria?ref_type=heads) for references

2) Kuberntes with openstack cloud provider. Refere to this [guide](https://github.com/eduardoefb/k8s-openstack-cloudprovider) for references.

#### 1 - Prepare Configuration file
Once the above requirements are satisfied, you need to create the configuration file `magma_config.yml` with passwords and other configurations.  Example below:

```yaml
namespace: orc8r 
prefix: orc8r
domain: lte.int
c: C=BR
cert_validity: 3650
branch: v1.8
kubeconfig_file: /home/kubeuser/.kube/config

ca_cert: /home/kubeuser/k8s/certs/regca.crt
ca_key: /home/kubeuser/k8s/certs/regca.key

registry:
  url: registry.kube.int
  username: registryuser
  password: 5c8e61cf4733fbd22711
  project: magma
  tag: 1.8.0

magma:
  admin_user: admin@magma
  admin_pass: 445a494ccb2cfbd60caf

  elasticsearch_volume_size: 100Gi
  elasticsearch_version: "8.8.0"
  prometheus_volume_size: 100Gi

  organizations:
    - name: custom
      admin_user: admin@custom.lte.int
      admin_pass: 3124258c7eb109c27c34
  
      network:
        id: custom 
        name: custom 
        lte_auth_amf: gAA=
        lte_auth_op: NUYwQUY2RjJEOEIzRkM5MzcxMDU5NDk2OThFRUE1RkI=
        mcc: 724
        mnc: 17
        tac: 100
        agw_id: agw01
        agw_name: agw01
  
  agw:
    s1:
      gateway: 10.3.0.1

  apn: 
    name: custom.net
    max_bandwidth_dl: 100000000
    max_bandwidth_ul: 100000000
    qos: 9

  subscribers:
    - imsi: "724170000000001"
      key: "00000000000000000000000000000001"
      opc: "00000000000000000000000000000001"
      apn: custom.net
      msisdn: "5531910000001"
      msin: "0000000001"
      imei: "356113022094151"
      manufacturer: "EURECOM"
      model: "LTE Android PC"
      pin: "0000"  
      hplmn: "72417"    

    - imsi: "724170000000002"
      key: "00000000000000000000000000000002"
      opc: "00000000000000000000000000000002"
      apn: custom.net
      msisdn: "5531910000002"
      msin: "0000000002"
      imei: "356113022094152"
      manufacturer: "EURECOM"
      model: "LTE Android PC"
      pin: "0000"  
      hplmn: "72417"    
      
    - imsi: "724170000000003"
      key: "00000000000000000000000000000003"
      opc: "00000000000000000000000000000003"
      apn: custom.net
      msisdn: "5531910000003"
      msin: "0000000003"
      imei: "356113022094153"
      manufacturer: "EURECOM"
      model: "LTE Android PC"
      pin: "0000" 
      hplmn: "72417"      
```

Then, encrypt your configuration file using ansible-vault
```shell
ansible-vault encrypt magma_config.yml
```

#### 2 - Start the deployment:

Start the `create.sh` script with the option `build`. It will build the images and upload to the registry:
Deploy:
```shell
bash create.sh build orc8r agw ran
```


#### 3 - Enodeb and UE:
Once the vms are created, build enodeb/ue separatelly:
```shell
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts 05_enodeb_ue.yml --ask-vault-password
```

#### 4 - Post installation:
Once magma is installed, if eu and gnodeb, you can connect to the UE and check if the session is established:
```shell
sudo ip addr show dev oaitun_ue1
```

Example:
```log
ubuntu@magma-ue01:~$ sudo ip addr show dev oaitun_ue1
5: oaitun_ue1: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none 
    inet 192.168.128.14/24 brd 192.168.128.255 scope global oaitun_ue1
       valid_lft forever preferred_lft forever
    inet6 fe80::392e:f213:9a79:e993/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
ubuntu@magma-ue01:~$ 
```

To validate the connection, add a static route via oaitun_ue1 interface:

First add a static route to your local ip address, to avoid to loss the connection with the UE:
```shell
ip route add <your local ssh ip addr> via <original default gw>
```

Than, delete the default gateway and add it to via oaitun_ue1
```shell
ip route del default
ip route add default dev  oaitun_ue1
```

#### In case of network changes, execute terraform as:
```shell
namespace=`cat namespace.txt`
bootstrapper=`kubectl -n ${namespace} get service bootstrapper-orc8r-nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"` 
api=`kubectl -n ${namespace} get service orc8r-nginx-proxy -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"`
controller=`kubectl -n ${namespace} get service orc8r-clientcert-nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"`
nms=`kubectl -n ${namespace} get service nginx-proxy -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"`
fluentd=`kubectl -n ${namespace} get service orc8r-fluentd-forward -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"`
kibana=`kubectl -n ${namespace} get service kibana-http-external -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"`

terraform_opts=`cat terraform_opts`
terraform apply ${terraform_opts} \
    -var "bootstrapper=${bootstrapper}" \
    -var "api=${api}" \
    -var "controller=${controller}" \
    -var "fluentd=${fluentd}" \
    -var "kibana=${kibana}" \
    -var "nms=${nms}" `cat terraform_opts`

# To replace agw:

terraform apply ${terraform_opts} \
    -var "bootstrapper=${bootstrapper}" \
    -var "api=${api}" \
    -var "controller=${controller}" \
    -var "fluentd=${fluentd}" \
    -var "kibana=${kibana}" \
    --replace openstack_compute_instance_v2.agw \
    -var "nms=${nms}" `cat terraform_opts`
   
```


