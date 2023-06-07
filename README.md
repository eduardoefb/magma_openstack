#### Deploy magma on kubespray 
Copy the kubespray certificate authority to the current directory

```
rm -rf certs
mkdir certs
cat ~/k8s/certs/regca.crt > certs/regca.crt
```

Deploy:
```shell
bash create.sh
```

Once the orchestrator and agw are deployed, execute the following script to integrate agw. The script will create the operator, network and agw as per defined in the `magma_config.yml` file.
```shell
bash integrate_agw.sh
```

To access the nms host url, open the `https://host.nms.<your-domain>`.  Example for domain `lte.int`: `https://host.nms.lte.int`


If you want to change the password, you can do so using the following command:
```shell
kubectl --namespace orc8r exec -it deploy/nms-magmalte -- yarn setAdminPassword host admin@magma Admin@123#
```

Please open the URL and create the operator and admin users for it. Additionally, add the organization and assign a user as an admin, along with their password:
```shell
https://host.nms.lte.int/
```

To access your operator's  url:
```log
admin@custom.lte.int
XTpOtJS5FrKg
```
Please note that the provided example credentials are for illustrative purposes only. Make sure to use the actual username and password generated during the operator creation process.


Once the operator is created (e.g., "custom"), navigate to its URL. and create the network¨
```shell
https://custom.nms.lte.int/

```

Obs: Alternativalley you can use the add_organization script (this organization will have access to all networks):
```shell
cd scripts
python3 add_organization.py \
  --admin_user admin@magma \
  --admin_password Admin@123# \
  --organization custom \
  --organization_admin_user admin@custom.lte.int \
  --domain lte.int \
  --organization_admin_password XTpOtJS5FrKg

python3 add_network.py \
  --organization custom \
  --organization_admin_user admin@custom.lte.int \
  --domain lte.int \
  --organization_admin_password XTpOtJS5FrKg \
  --network_id custom \
  --mcc 724 \
  --mnc 17 \
  --tac 100 \
  --amf gAA= \
  --network custom  


python3 add_gw.py \
  --organization custom \
  --organization_admin_user admin@custom.lte.int \
  --domain lte.int \
  --organization_admin_password XTpOtJS5FrKg \
  --network_id custom \
  --network custom \
  --gw_name agw01 \
  --gw_id agw01 \
  --gw_config_file ../../../files/agw_info.txt

```


To access the API, please utilize the provided URL:   

Note: In order to gain access to this API, it is necessary to employ the certificate/key stored as admin_operator.pfx, which can be found in the certs directory.



API Examples:
List tenannts:
```shell
alias scurl='curl --cacert certs/rootCA.pem --cert certs/admin_operator.pem --key certs/admin_operator.key.pem'
scurl -X 'GET' \
  'https://api.lte.int/magma/v1/tenants' \
  -H 'accept: application/json'
```
List networks:
```shell
alias scurl='curl --cacert certs/rootCA.pem --cert certs/admin_operator.pem --key certs/admin_operator.key.pem'
scurl \
  -X 'GET' \
  'https://api.lte.int/magma/v1/lte' \
  -H 'accept: application/json'
```

Create network:
```shell
alias scurl='curl --cacert certs/rootCA.pem --cert certs/admin_operator.pem --key certs/admin_operator.key.pem'
scurl -X 'POST' \
  'https://api.lte.int/magma/v1/lte' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "cellular": {
    "epc": {
      "default_rule_id": "default_rule_1",
      "gx_gy_relay_enabled": false,
      "hss_relay_enabled": false,
      "lte_auth_amf": "gAA=",
      "lte_auth_op": "EREREREREREREREREREREQ==",
      "mcc": "724",
      "mnc": "17",
      "network_services": [
        "policy_enforcement"
      ],
      "tac": 1
    },
    "ran": {
      "bandwidth_mhz": 20,
      "tdd_config": {
        "earfcndl": 44590,
        "special_subframe_pattern": 7,
        "subframe_assignment": 2
      }
    }
  },
  "description": "lte_network",
  "dns": {
    "enable_caching": false,
    "local_ttl": 0
  },
  "features": {
    "features": {
      "placeholder": "true"
    }
  },
  "id": "lte_network",
  "name": "lte_network"
}'
```

Get a generic network description:
```shell
alias scurl='curl --cacert certs/rootCA.pem --cert certs/admin_operator.pem --key certs/admin_operator.key.pem'
scurl -X 'GET' \
  'https://api.lte.int/magma/v1/networks/custom' \
  -H 'accept: application/json'
```




And delete the ubuntu instance:
```shell
terraform destroy \
  -var "oam_network=lb" \
  -var "oam_subnet=lb" \
  -var "s1_network=clabext01" \
  -var "s1_subnet=clabext01_ipv4" \
  -var "key_pair_file=/home/eduardoefb/.ssh/id_rsa.pub" \
  -var "image=ubuntu_20.04" \
  --auto-approve
```

mkdir -p /var/opt/magma/configs
cat << EOF > /var/opt/magma/configs/control_proxy.yml
cloud_address: controller.lte.int
cloud_port: 443
bootstrap_address: bootstrapper-controller.lte.int
bootstrap_port: 443
fluentd_address: fluentd.lte.int
fluentd_port: 24224
rootca_cert: /var/opt/magma/tmp/certs/rootCA.pem
EOF


cat << EOF >> /etc/hosts
10.8.0.49 controller.lte.int
10.8.0.34 bootstrapper-controller.lte.int
10.8.0.42 fluentd.lte.int
EOF

mkdir -p /var/opt/magma/tmp/certs/            
cat << EOF > /var/opt/magma/tmp/certs/rootCA.pem          
-----BEGIN CERTIFICATE-----
MIIDLTCCAhWgAwIBAgIUeWjNwa4P2XIVZ9iWpPOFlbDnl8wwDQYJKoZIhvcNAQEL
BQAwJjELMAkGA1UEBhMCVVMxFzAVBgNVBAMMDnJvb3RjYS5sdGUuaW50MB4XDTIz
MDUzMDE0MTIzOFoXDTMzMDUyNzE0MTIzOFowJjELMAkGA1UEBhMCVVMxFzAVBgNV
BAMMDnJvb3RjYS5sdGUuaW50MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
AQEA9Qmh2oIxyUEdvPvZ1o+XQ8EqSYctN5i9X35Ii573A673Kqlb3aWeoyatyJns
XIDQNkI6Y02R/xF7XTD7sLnyB+v51JGH9CuqI47Emodkweo/ykyAgloLDH8iQDKC
dS6Jv7aWpQcmTsrtdH0Pd305uQQ9tem9Zg3LtK39qYw79ViYulnZ1UrKvDdZug5W
zOHLRkLeSqMXtB3abJkk27z47dDpXZ66smgwBUNAd3M7uWDM0UTpaLhyDRi5AlCM
WyfaUHlY+zuXnfGDQ0kpdtdYHzDHuBlVnM6a3GopE81Twng8dwgrwPI2IuXqUtrW
hfobjdPo5h90xKjDEk0SqzfkzwIDAQABo1MwUTAdBgNVHQ4EFgQUeNuhAr2r80N3
PVvCb4XBImZdZAIwHwYDVR0jBBgwFoAUeNuhAr2r80N3PVvCb4XBImZdZAIwDwYD
VR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAoCAPpIZQpUecOdiRXe/h
ivAvRz9JSYWpX+Khr453nJ8fMIUNuKzM8w1Wx1q3+y/9g+3jdmIgDwJUrBrSMygL
4PqEwvRWPHJ2AzYckQnzcUsp8/WW9F/+9ecEgDwsgVydLa88CUp9jKDqafTbAIoK
owGWx/8vEiOGrH8mfFhuCdgdwUXahYPzQHi/iO+n3SSIpnaB+hEu2IPrUEQTDJhR
WgPPbMVXz3XcHgmUxbEMKR++Ya1NI/EzhC5y1PP157htbhWaJPW3m3A/nPYcdrQR
pOxJhVfeNwKlJplPLOdnOgv6pcAykJVcXiGg/l2/YhvESiL/zr+tTU9L7+RoVF3y
bg==
-----END CERTIFICATE-----
EOF



show_gateway_info.py

sudo service magma@* stop
sudo service magma@magmad restart
journalctl -u magma@magmad -f

```


To destroy:
```shell
terraform destroy \
  -var "oam_network=lb" \
  -var "oam_subnet=lb" \
  -var "s1_network=clabext01" \
  -var "s1_subnet=clabext01_ipv4" \
  -var "key_pair_file=/home/eduardoefb/.ssh/id_rsa.pub" \
  --auto-approve
```