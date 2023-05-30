#### Deploy magma on kubespray 
Copy the kubespray certificates to the current directory

```
rm -rf certs
cp -rfv ~/k8s/certs .
```

Deploy:
```shell
bash create.sh -d
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

#### Deploy agw:

Create agw instance
```shell
cd agw
terraform apply \
  -var "oam_network=lb" \
  -var "oam_subnet=lb" \
  -var "s1_network=clabext01" \
  -var "s1_subnet=clabext01_ipv4" \
  -var "key_pair_file=/home/eduardoefb/.ssh/id_rsa.pub" \
  --auto-approve

terraform destroy \
  -var "oam_network=lb" \
  -var "oam_subnet=lb" \
  -var "s1_network=clabext01" \
  -var "s1_subnet=clabext01_ipv4" \
  -var "key_pair_file=/home/eduardoefb/.ssh/id_rsa.pub" \
  --auto-approve
```

Start installation:
```shell
ssh <agw_ip>
sudo su - 
wget https://raw.githubusercontent.com/magma/magma/v1.8/lte/gateway/deploy/agw_install_ubuntu.sh
bash agw_install_ubuntu.sh 
# After reboot:
journalctl -fu agw_installation.service

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
10.8.0.133 controller.lte.int
10.8.0.30 bootstrapper-controller.lte.int
10.8.0.250 fluentd.lte.int
EOF

mkdir -p /var/opt/magma/tmp/certs/            
cat << EOF > /var/opt/magma/tmp/certs/rootCA.pem
-----BEGIN CERTIFICATE-----
MIIDLTCCAhWgAwIBAgIULdP7ClgUGZjSR/76AgYmNMVQ0CswDQYJKoZIhvcNAQEL
BQAwJjELMAkGA1UEBhMCVVMxFzAVBgNVBAMMDnJvb3RjYS5sdGUuaW50MB4XDTIz
MDUzMDAwMDg0NFoXDTMzMDUyNzAwMDg0NFowJjELMAkGA1UEBhMCVVMxFzAVBgNV
BAMMDnJvb3RjYS5sdGUuaW50MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
AQEA1zU5Rf/Cz9bqXDWDAwF3dJD3rWxII/Xj3pJQS8o8KWJ+of+8jJIZPxsCcSoQ
tn0NuTMSKsF0WAmThsq6oniD3kiXHr9fZBg3qCkdT53ehRQge2hX/t5e8V1q6V+n
6DNCpWYajUaPvQoShGzqqg2Nud6T+/weYAxWfcG5O/WAK9qJCEsU++JCLUHWLzR0
z1D88jZ237vwrOsklt3/6rcvwjYsgbXITBnODccsu8aAvONuOR3Q2SnzllnwHtKX
Km5OpQZDCM+PlqqXw1x6KooI5PWg8JPMBeDChzW7b/P2bgsq3ffL+H9GnfKJN26P
b9QAw/4vvggayu7RLpA+iZexNwIDAQABo1MwUTAdBgNVHQ4EFgQUa8wQsvT+wvvX
KdnUV7kRk/QAqV8wHwYDVR0jBBgwFoAUa8wQsvT+wvvXKdnUV7kRk/QAqV8wDwYD
VR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAxbnwwWiVjZEyec/dmEKE
tXUQ/yVn/0Y0F6YsQnl8EdmdwdN4GkNZhmnSAIazNPTNoRLqDg+Yhrmsc+sOR0IB
MyhSHZDxRBc/jm8wOzJHqlAcKHnDn3EDrTxNmFtDVXhf3d9mEt1hnbFFw7RJZMwV
+SAPNUFENNIuPseHOarhVV19v279WGjq98DzMJymlHpCxh+bFGcY3NgJh7JPozQf
Vn7A8pOuvphR+OdKzNEgO/Q+GXiOMtw+g6B/ohSjhwp4rreLQ1yKsyCzGMOX5CCv
bL1bsfE+3iXpWnNq7RkWd0OwcmqXgVipwyER9kNdVAjXz/vLMJylYOW9wWeC+ypb
qQ==
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