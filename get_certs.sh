#!/bin/bash

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts get_certs.yml --ask-vault-password
