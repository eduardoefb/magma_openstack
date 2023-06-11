#!/bin/bash
namespace=`cat namespace.txt`
timeout 20 kubectl delete namespace ${namespace}
terraform destroy --auto-approve