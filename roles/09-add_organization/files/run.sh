#!/bin/bash

cd /root/
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin xvfb-run /usr/bin/python3 add_organization.py \
  --admin_user admin@magma \
  --admin_password Admin@123# \
  --organization custom \
  --organization_admin_user admin@custom.lte.int \
  --organization_admin_password XTpOtJS5FrKg \
  --headless