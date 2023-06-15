#!/bin/bash
source inventory.sh

if [ "${1}" == "--help" ]; then 
    echo "Usage:"
    echo "${0} [build] [ran]"
    echo "  build: To build and upload the images to the repository;"
    echo "  orc8r: Deploy or redeploy orc8r;"
    echo "  agw  : Deploy or redeploy agw;"
    echo "  ran  : To deploy the ran environment."
    exit 0
fi

# Ask for the ansible-vault password
read -s -p "Enter ansible-vault password: " ansible_password
echo

if [ ! -d ssh_keys ]; then
    mkdir -p ssh_keys
fi

if [ ! -f ssh_keys/id_rsa -o ! -f ssh_keys/id_rsa.pub ]; then
    ssh-keygen -t rsa -f ssh_keys/id_rsa -N ''
fi


terraform_opts=""
orc8r_redeploy=0
for opt in ${@}; do
    if [ "${opt}" == "build" ]; then 
        ansible_opts="${ansible_opts} -e build_images=true"
    elif [ "${opt}" == "orc8r" ]; then 
        ansible_opts="${ansible_opts} -e orc8r=true"        
        orc8r_redeploy=1                     
    elif [ "${opt}" == "agw" ]; then 
        ansible_opts="${ansible_opts} -e agw=true"  
    elif [ "${opt}" == "ran" ]; then
        ansible_opts="${ansible_opts} -e create_ran=true"
        terraform_opts="${terraform_opts} -var=create_ran=true"
    fi
done

echo "${terraform_opts}" > terraform_opts 
echo "${ansible_opts}" > ansible_opts 
rm *.txt 2>/dev/null

terraform apply ${terraform_opts} --auto-approve

for f in *.txt; do echo >> $f; done
sed -i '/^$/d' *.txt

update_inventory

#if [ ! -d certs ]; then 
build_certificates
#fi

# Trigger agw installation
if ! ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts ${ansible_opts} 00_trigger_agw.yml --vault-password-file <(echo "$ansible_password"); then 
    exit 1
fi

# Start orc8r installation
if ! ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts ${ansible_opts} 01_deploy_orc8r.yml --vault-password-file <(echo "$ansible_password"); then 
    exit 1
fi

# DNS entries

namespace=`cat namespace.txt`
bootstrapper=`kubectl -n ${namespace} get service bootstrapper-orc8r-nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"` 
api=`kubectl -n ${namespace} get service orc8r-nginx-proxy -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"`
controller=`kubectl -n ${namespace} get service orc8r-clientcert-nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"`
nms=`kubectl -n ${namespace} get service nginx-proxy -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"`
fluentd=`kubectl -n ${namespace} get service orc8r-fluentd-forward -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"`
kibana=`kubectl -n ${namespace} get service kibana-http-external -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "0.0.0.0"`

cat << EOF > names.yml
controller: ${controller}
bootstrapper: ${bootstrapper}
fluentd: ${fluentd}
EOF

terraform apply ${terraform_opts} \
    -var "bootstrapper=${bootstrapper}" \
    -var "api=${api}" \
    -var "controller=${controller}" \
    -var "fluentd=${fluentd}" \
    -var "kibana=${kibana}" \
    -var "nms=${nms}" --auto-approve


update_inventory

# After orc8r installation, continue with agw
if ! ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts ${ansible_opts} 02_continue_agw.yml --vault-password-file <(echo "$ansible_password"); then 
    exit 1
fi

# create organizations
if ! ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts ${ansible_opts} 03_organization.yml --vault-password-file <(echo "$ansible_password"); then 
    exit 1
fi

# Integrate agw
if ! ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts ${ansible_opts} 04_integrate_agw.yml --vault-password-file <(echo "$ansible_password"); then 
    exit 1
fi

# Gnodeb and ue
#if ! ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts ${ansible_opts} 05_gnodeb_ue.yml --vault-password-file <(echo "$ansible_password"); then 
#    exit 1
#fi


