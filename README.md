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

Once the orc8r and nms are deployed, create the admin user and password:
```shell
kubectl --namespace orc8r exec -it deploy/nms-magmalte -- yarn setAdminPassword host admin@magma Admin@123#
```

Open the url and create the operator and admin user for it:
```shell
https://host.nms.lte.int/
```

Once operator is created, (ex:  custom), enter on it's url
```shell
https://custom.nms.lte.int/
```
Example:
```log
admin@custom.lte.int
XTpOtJS5FrKg
```

Create an operator and an admin user for it and open the url
https://custom.nms.


To access the api:
https://api.lte.int/swagger/v1/ui/



API Examples:
List networks:
```shell
curl \
  --cacert certs/rootCA.pem \
  --cert certs/admin_operator.pem \
  --key certs/admin_operator.key.pem \
  -X 'GET' \
  'https://api.lte.int/magma/v1/lte' \
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