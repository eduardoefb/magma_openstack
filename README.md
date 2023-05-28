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
admin@custom.lte.int
XTpOtJS5FrKg

Create an operator and an admin user for it and open the url
https://custom.nms.