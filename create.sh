#!/bin/bash
function update_inventory(){
    cat /dev/null > hosts
    cat /dev/null > vars.yml
    unset bastian_name
    unset bastian_int 
    unset bastian_ext    

    bastian_id=`cat bastian.txt | head -1 | awk '{print $1}'`
    addr_line=`openstack server show ${bastian_id} -f value -c addresses`
    bastian_int=$(awk -F \' '{print $4}' <<< ${addr_line})
    bastian_ext=$(awk -F \' '{print $6}' <<< ${addr_line})

    echo "[BASTIAN]" >> hosts    
    echo "${bastian_ext}" >> hosts

    echo >> vars.yml
    echo >> hosts
    echo "[ALL]" >> hosts 
    echo "all:" >> vars.yml
    echo ${bastian_ext} >> hosts
    
    echo "  - ${bastian_ext}" >> vars.yml

    echo >> vars.yml
    echo "int_net: `cat int_network.txt`" >> vars.yml
    echo "domain: `cat domain.txt | sed 's/.$//g'`" >> vars.yml

    echo >> hosts
    echo "[all:vars]" >> hosts 
    echo "ansible_ssh_private_key_file=ssh_keys/id_rsa" >> hosts
    echo >> hosts  
    echo >> vars.yml
    echo "dns_nameservers:" >> vars.yml
    for i in `cat dns.txt`; do
        echo "  - ${i}" >> vars.yml
    done
    echo >> vars.yml

    echo "openstack:" >> vars.yml
    echo "  auth_url: ${OS_AUTH_URL}" >> vars.yml
    echo "  cacert: ${OS_CACERT}" >> vars.yml
    echo "  username: ${OS_USERNAME}" >> vars.yml
    echo "  password: ${OS_PASSWORD}" >> vars.yml
    echo "  project_name: ${OS_PROJECT_NAME}" >> vars.yml
    echo "  domain_name: ${OS_USER_DOMAIN_NAME}" >> vars.yml
    echo "  project_id: `openstack project show ${OS_PROJECT_NAME} -f value -c id`"  >> vars.yml
    echo "  region: `openstack region list -f value -c Region | head -1`" >> vars.yml
    echo "  os_identity_api_version: ${OS_IDENTITY_API_VERSION}" >> vars.yml
    echo "  os_image_api_version: ${OS_IMAGE_API_VERSION}" >> vars.yml
    echo "  os_project_domain_name: ${OS_PROJECT_DOMAIN_NAME}" >> vars.yml
    echo "  os_user_domain_name: ${OS_USER_DOMAIN_NAME}" >> vars.yml
    
    echo >> vars.yml
    echo "internal_subnet_id: `cat internal_subnet_id.txt`" >> vars.yml
    echo "floating_network_id: `cat floating_network_id.txt`" >> vars.yml
}

export DOMAIN="k8so.int"
export LB_PREFIX="k8so-lb"

# Ask for the ansible-vault password
read -s -p "Enter ansible-vault password: " ansible_password
echo

if [ ! -d ssh_keys ]; then
    mkdir -p ssh_keys
fi

if [ ! -f ssh_keys/id_rsa -o ! -f ssh_keys/id_rsa.pub ]; then
    ssh-keygen -t rsa -f ssh_keys/id_rsa -N ''
fi

if [ "${1}" == "-d" ]; then
    cwd=`pwd`
    cd dns
    source dns-rc
    terraform destroy \
    -var "zone=${domain}" \
    -var "bootstrapper=${bootstrapper}" \
    -var "api=${api}" \
    -var "controller=${controller}" \
    -var "nms=${nms}" --auto-approve    
    cd `cwd`
    terraform destroy --auto-approve
fi

terraform apply --auto-approve
for f in *.txt; do echo >> $f; done
sed -i '/^$/d' *.txt

update_inventory

if ! ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts run.yml --vault-password-file <(echo "$ansible_password"); then
    exit 1
fi

cwd=`pwd`
cd dns
namespace=`grep -oP '(?<=^namespace:\s).*' ../magma_config.yml`
domain=`grep -oP '(?<=^domain:\s).*' ../magma_config.yml`
bootstrapper=`kubectl -n ${namespace} get service bootstrapper-orc8r-nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'`
api=`kubectl -n ${namespace} get service orc8r-nginx-proxy -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'`
controller=`kubectl -n ${namespace} get service orc8r-clientcert-nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'`
nms=`kubectl -n ${namespace} get service nginx-proxy -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'`


cat << EOF > dns-rc
namespace=${namespace}
domain=${domain}
bootstrapper=${bootstrapper}
api=${api}
controller=${controller}
nms=${nms}
EOF

terraform init

terraform destroy \
  -var "zone=${domain}" \
  -var "bootstrapper=${bootstrapper}" \
  -var "api=${api}" \
  -var "controller=${controller}" \
  -var "nms=${nms}" --auto-approve

terraform apply \
  -var "zone=${domain}" \
  -var "bootstrapper=${bootstrapper}" \
  -var "api=${api}" \
  -var "controller=${controller}" \
  -var "nms=${nms}" --auto-approve



