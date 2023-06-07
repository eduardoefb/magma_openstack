#!/usr/bin/python

from selenium import webdriver
from selenium.webdriver import ActionChains
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support.ui import Select
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
import time
import yaml
from yaml.loader import SafeLoader
import mouse
from getpass import getpass
import os
from sys import exit
import argparse
import re

#  Get user entered options
parser = argparse.ArgumentParser(description='Add organization script')
parser.add_argument('--organization', help='Name of the organization', required=True)
parser.add_argument('--organization_admin_user', help='Name of the admin user for the organization', required=True)
parser.add_argument('--organization_admin_password', help='Name of the admin password for the organization', required=True)
parser.add_argument('--network', help='Name of the network', required=True)
parser.add_argument('--network_id', help='Id of the network', required=True)
parser.add_argument('--domain', help='URL Domain (Ex: lte.int', required=True)
parser.add_argument('--gw_name', help='Gateway name (Ex: agw01)', required=True)
parser.add_argument('--gw_id', help='Gateway name (Ex: agw01)', required=True)
parser.add_argument('--gw_config_file', help='Gateway config file', required=True)
parser.add_argument('--headless', action='store_true', help='Run in headless mode')

args = parser.parse_args()
organization = args.organization
organization_admin_user = args.organization_admin_user
organization_admin_password = args.organization_admin_password
domain = args.domain
network = args.network
network_id = args.network_id
gw_id = args.gw_id
gw_name = args.gw_name
gw_config_file = args.gw_config_file

tmout=2000
inst_tmout=20000
options = Options()

if args.headless:
    options.add_argument('-headless')


hardware_id_regex = r"Hardware ID\s+-+\s+([\w-]+)"
challenge_key_regex = r"Challenge key\s+-+\s+([\w/+=]+)"
hardware_id = None
challenge_key = None
with open(gw_config_file, 'r') as file:
    file_content = file.read()

# Extract Hardware ID
match = re.search(hardware_id_regex, file_content)
if match:
    hardware_id = match.group(1)

# Extract Challenge key
match = re.search(challenge_key_regex, file_content)
if match:
    challenge_key = match.group(1)



# Open browser:
driver = webdriver.Firefox(options=options)
driver.get(f"https://{organization}.nms.{domain}/nms/{network_id}/equipment/overview/gateway")


# Login:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div/div/div[2]/form/div[1]/li[1]/div/div[2]/div/div/input')).send_keys(organization_admin_user)
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div/div/div[2]/form/div[1]/li[2]/div/div[2]/div/div/input')).send_keys(organization_admin_password)
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div/div/div[2]/form/div[2]/button/span[1]')).click()


# Add gw:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/div/div/div[1]/div/div[2]/ul/li[2]/div[2]/div/div/div[2]/div/div[1]/button/span[1]')).click()


# Gateway Name:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[1]/div/div[2]/div/input')).send_keys(gw_name)

# Gateway ID:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[2]/div/div[2]/div/input')).send_keys(gw_id)

# HW uuid:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[3]/div/div[2]/div/input')).send_keys(hardware_id)

# Version:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[4]/div/div[2]/div/input')).send_keys("1.8.0")

# GW Descryption
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[5]/div/div[2]/div/input')).send_keys("AGW")


# Challenge Key:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[6]/div/div[2]/div/input')).send_keys(challenge_key)

# Save and continue:
max_attempts = 5
attempt=0
for i in range(3):
    while True:
        try:
            attempt+=1
            WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[4]/button[2]/span[1]')).click()        
            break
        except:
            time.sleep(1)
        if attempt > max_attempts:
            break

driver.close()
driver.quit()      