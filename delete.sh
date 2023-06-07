#!/bin/bash
cwd=`pwd`
cd dns
sed -i 's|\.$||g' dns-rc
source dns-rc
terraform destroy \
    -var "zone=${domain}" \
    -var "bootstrapper=${bootstrapper}" \
    -var "api=${api}" \
    -var "controller=${controller}" \
    -var "fluentd=${fluentd}" \
    -var "kibana=${kibana}" \
    -var "nms=${nms}" --auto-approve    

namespace=`cat ../namespace.txt`
domain=`cat ../domain.txt`
kubectl delete namespace ${namespace}
cd ${cwd}

terraform destroy --auto-approve