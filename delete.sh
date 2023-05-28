#!/bin/bash
cwd=`pwd`
cd dns
source dns-rc
terraform destroy \
    -var "zone=${domain}" \
    -var "bootstrapper=${bootstrapper}" \
    -var "api=${api}" \
    -var "controller=${controller}" \
    -var "nms=${nms}" --auto-approve    
cd ${cwd}

namespace=`grep -oP '(?<=^namespace:\s).*' magma_config.yml`
kubectl delete namespace ${namespace}

terraform destroy --auto-approve