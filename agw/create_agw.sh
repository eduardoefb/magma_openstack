#!/bin/bash

terraform destroy \
  -var "oam_network=lb" \
  -var "oam_subnet=lb" \
  -var "s1_network=clabext01" \
  -var "s1_subnet=clabext01_ipv4" \
  -var "key_pair_file=/home/eduardoefb/.ssh/id_rsa.pub" \
  --auto-approve
  
terraform apply \
  -var "oam_network=lb" \
  -var "oam_subnet=lb" \
  -var "s1_network=clabext01" \
  -var "s1_subnet=clabext01_ipv4" \
  -var "key_pair_file=/home/eduardoefb/.ssh/id_rsa.pub" \
  --auto-approve


cat << EOF > hosts
[AGW]
`cat oam_ip.txt`
EOF

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts agw.yml 
