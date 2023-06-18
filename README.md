## Deploying Magma on OpenStack Environment

### Requirements:
To install Magma using this procedure, make sure you have the following services installed in your OpenStack environment:

1. **OpenStack services:**
   - Nova
   - Cinder
   - Neutron
   - Designator
   - Octavia

For installation instructions, refer to the [OpenStack Ubuntu Guide](https://gitlab.com/eduardoefb/openstack-ubuntu/-/tree/victoria?ref_type=heads).

2. **Kubernetes with OpenStack Cloud Provider:**
   To integrate Kubernetes with OpenStack, follow the steps provided in the [Kubernetes OpenStack Cloud Provider Guide](https://github.com/eduardoefb/k8s-openstack-cloudprovider).

Please ensure that you have met all the requirements before proceeding with the Magma deployment.


## 1. Prepare Configuration File
Once the above requirements are satisfied, you need to create the configuration file `magma_config.yml` with passwords and other configurations. Example below:


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

### 2 - Start the deployment:
Start the `create.sh` script with the option `build`. It will build the images and upload them to the registry.

```shell
bash create.sh build orc8r agw ran
```

### 3 - Enodeb and UE:
Once the virtual machines (VMs) are created, build the enodeb/UE separately using the following command:
```shell
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts 05_enodeb_ue.yml --ask-vault-password
```

### 4 - Post installation:
Once Magma is installed, if using UE and eNodeB, you can check if eNodeB is connected to the MME (AGW):

1. Connect to the eNodeB and check the status of the `enodeb.service` status:
```shell
sudo systemctl status enodeb.service
```

2. Check if the eNodeB is connected to the MME (AGW) by viewing the network connections and sockets:
```shell
sudo netstat -anS
```
This command will show the active network connections and open sockets, allowing you to verify the connection between the eNodeB and the MME (AGW).

3. Connect to the UE and check the status of the `ue.service`:
```shell
sudo systemctl status ue.service
```
This command will display the status of the ue.service, providing information about the UE's connectivity.


4. If everything is fine, move to the `ue` namespace and test the internet connection:
```shell
sudo su - 
ip netns exec ue bash
ping 8.8.8.8
```

These commands will allow you to enter the ue namespace and test the internet connection by pinging the IP address 8.8.8.8.

Make sure to execute these steps after completing the Magma installation to ensure the proper connection between the eNodeB, MME (AGW), and UE.


