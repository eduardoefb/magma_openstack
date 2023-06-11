function build_certificates(){

    # Copy ca files from registry:
    ftmp=`mktemp`

    ansible-vault view magma_config.yml --vault-password-file <(echo "$ansible_password") > ${ftmp}
    ca_cert=`cat ${ftmp} | grep -oP '(?<=^ca_cert:\s)(.*)'`
    ca_key=`cat ${ftmp} | grep -oP '(?<=^ca_key:\s)(.*)'`
    rm ${ftmp}


    if [ ! -f ${ca_key} ]; then
        echo "${ca_key} not found!"
        exit 1
    fi

    if [ ! -f ${ca_cert} ]; then
        echo "${ca_cert} not found!"
        exit 1
    fi

    rm -rf certs 2>/dev/null
    mkdir certs
    if ! cat "${ca_cert}" > certs/rootCA.pem; then 
        echo "Error: Failed to copy ${ca_cert}! Please verify the file path."
        exit 1
    fi


    # Create the certificates:
    ftmp=`mktemp`
    ansible-vault view magma_config.yml --vault-password-file <(echo "$ansible_password") > ${ftmp}
    domain=`cat ${ftmp} | grep -oP '(?<=^domain:\s)(.*)'`
    c=`cat ${ftmp} | grep -oP '(?<=^c:\s)(.*)'`
    cert_validity=`cat ${ftmp} | grep -oP '(?<=^cert_validity:\s)(.*)'`
    rm ${ftmp}

    # Controller:
    openssl genrsa -out certs/controller.key 2048
    openssl req -new -key certs/controller.key -out certs/controller.csr -subj "/${c}/CN=*.$domain"

    # Create an extension config file
    > certs/${domain}.ext cat <<-EOF
basicConstraints=CA:FALSE
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.$domain
DNS.2 = *.nms.$domain
DNS.3 = *.staging.$domain
DNS.4 = *.nms.staging.$domain
EOF

    openssl x509 -req -in certs/controller.csr -CA ${ca_cert} -CAkey ${ca_key} -CAcreateserial -out certs/controller.crt -days ${cert_validity} -sha256 -extfile certs/${domain}.ext

    # NMS:
    openssl genrsa -out certs/nms_nginx.key 2048
    openssl req -new -key certs/nms_nginx.key -out certs/nms_nginx.csr -subj "/${c}/CN=*.$domain"
    openssl x509 -req -in certs/nms_nginx.csr -CA ${ca_cert} -CAkey ${ca_key} -CAcreateserial -out certs/nms_nginx.pem -days ${cert_validity} -sha256 -extfile certs/${domain}.ext

    # Create the bootstrapper key:
    openssl genrsa -out certs/bootstrapper.key 2048

    # Create certifier CA:
    openssl genrsa -out certs/certifier.key 2048
    openssl req -x509 -new -nodes -key certs/certifier.key -sha256 -days ${cert_validity} -out certs/certifier.pem -subj "/${c}/CN=certifier.$domain"

    # Creating domain-proxy fluentd certs:
    openssl genrsa -out certs/dp_fluentd.key 2048
    openssl req -new -key certs/dp_fluentd.key -out certs/dp_fluentd.csr -subj "/${c}/CN=dp-fluentd.$domain"
    openssl x509 -req -in certs/dp_fluentd.csr -CA certs/certifier.pem -CAkey certs/certifier.key -CAcreateserial -out certs/dp_fluentd.pem -days ${cert_validity} -sha256

    # Creating fluentd certs:
    openssl genrsa -out certs/fluentd.key 2048
    openssl req -new -key certs/fluentd.key -out certs/fluentd.csr -subj "/${c}/CN=fluentd.$domain"
    openssl x509 -req -in certs/fluentd.csr \
    -CA certs/certifier.pem -CAkey certs/certifier.key -CAcreateserial \
    -out certs/fluentd.pem -days ${cert_validity} -sha256

    # Creating admin_operator cert:
    openssl genrsa -out certs/admin_operator.key.pem 2048
    openssl req -new -key certs/admin_operator.key.pem -out certs/admin_operator.csr -subj "/${c}/CN=admin_operator"
    openssl x509 -req -in certs/admin_operator.csr -CA certs/certifier.pem -CAkey certs/certifier.key -CAcreateserial -out certs/admin_operator.pem -days ${cert_validity} -sha256

    # Remove csr files:
    rm certs/*.csr

}

function update_inventory(){
    cat /dev/null > hosts
    cat /dev/null > vars.yml
    unset bastian_name
    unset bastian_int 
    unset bastian_ext    

    bastian_id=`cat bastian.txt | head -1 | awk '{print $1}'`
    agw_id=`cat agw.txt | head -1 | awk '{print $1}'`    
    addr_line_bastian=`openstack server show ${bastian_id} -f value -c addresses`
    addr_line_agw=`openstack server show ${agw_id} -f value -c addresses`
    bastian_int=$(awk -F \' '{print $4}' <<< ${addr_line_bastian})
    bastian_ext=$(awk -F \' '{print $6}' <<< ${addr_line_bastian})
    agw_int=$(awk -F \' '{print $4}' <<< ${addr_line_agw})
    agw_ext=$(awk -F \' '{print $6}' <<< ${addr_line_agw})

    if [ -f gnodeb.txt ]; then
        gnodeb_id=`cat gnodeb.txt | head -1 | awk '{print $1}'`
        addr_line_gnodeb=`openstack server show ${gnodeb_id} -f value -c addresses`
        gnodeb_int=$(awk -F \' '{print $4}' <<< ${addr_line_gnodeb})
        gnodeb_ext=$(awk -F \' '{print $6}' <<< ${addr_line_gnodeb})   
    fi 
    
    if [ -f ue.txt ]; then
        ue_id=`cat ue.txt | head -1 | awk '{print $1}'`
        addr_line_ue=`openstack server show ${ue_id} -f value -c addresses`
        ue_int=$(awk -F \' '{print $4}' <<< ${addr_line_ue})
        ue_ext=$(awk -F \' '{print $6}' <<< ${addr_line_ue})   
    fi 

    echo "[BASTIAN]" >> hosts    
    echo "${bastian_ext}" >> hosts
    echo >> hosts
    echo "[AGW]" >> hosts    
    echo "${agw_ext}" >> hosts

    if [ -f gnodeb.txt ]; then 
        echo >> hosts
        echo "[GNODEB]" >> hosts 
        echo "${gnodeb_ext}" >> hosts 
    fi

    if [ -f ue.txt ]; then     
        echo >> hosts
        echo "[UE]" >> hosts 
        echo "${ue_ext}" >> hosts 
    fi

    echo >> vars.yml
    echo >> hosts
    echo "[ALL]" >> hosts 
    echo ${bastian_ext} >> hosts
    echo ${agw_ext} >> hosts
    if [ -f gnodeb.txt ]; then 
        echo ${gnodeb_ext} >> hosts
    fi

    if [ -f ue.txt ]; then
        echo ${ue_ext} >> hosts
    fi

    echo "all:" >> vars.yml    
    echo "  - ${bastian_ext}" >> vars.yml
    echo "  - ${agw_ext}" >> vars.yml
    if [ -f gnodeb.txt ]; then 
        echo "  - ${gnodeb_ext}" >> vars.yml
    fi
    if [ -f ue.txt ]; then 
        echo "  - ${ue_ext}" >> vars.yml
    fi
    echo >> vars.yml
    echo "bastian:" >> vars.yml    
    echo "  - ${bastian_ext}" >> vars.yml
    echo >> vars.yml    
    echo "agw:" >> vars.yml    
    echo "  - ${agw_ext}" >> vars.yml
    echo >> vars.yml 
    
    if [ -f gnodeb.txt ]; then 
        echo "gnodeb: ${gnodeb_ext}" >> vars.yml    
        echo "gnodeb_int: ${gnodeb_int}" >> vars.yml      
    fi

    if [ -f ue.txt ]; then 
        echo "ue: ${ue_ext}" >> vars.yml    
        echo "ue_int: ${ue_int}" >> vars.yml    
    fi
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
    s1_subnet=`head -1 agw_s1_subnet.txt`
    s1_subnet_cidr=`openstack subnet show ${s1_subnet} -f value -c cidr`
    echo "s1_subnet_cidr: ${s1_subnet_cidr}" >> vars.yml

    if [ -f agw_s1_ip.txt ]; then 
        echo "agw_s1_ip: `head -1 agw_s1_ip.txt`" >> vars.yml
    fi

    if [ -f gnodeb_s1_ip.txt ]; then 
        echo "gnodeb_s1_ip: `head -1 gnodeb_s1_ip.txt`" >> vars.yml
    fi

    echo "agw_s1_netmask: `echo $s1_subnet_cidr | awk -F '/' '{print $NF}'`" >> vars.yml
}
