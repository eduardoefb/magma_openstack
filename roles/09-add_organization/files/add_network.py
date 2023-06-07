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

#  Get user entered options
parser = argparse.ArgumentParser(description='Add organization script')
parser.add_argument('--organization', help='Name of the organization', required=True)
parser.add_argument('--organization_admin_user', help='Name of the admin user for the organization', required=True)
parser.add_argument('--organization_admin_password', help='Name of the admin password for the organization', required=True)
parser.add_argument('--network', help='Name of the network', required=True)
parser.add_argument('--network_id', help='Id of the network', required=True)
parser.add_argument('--domain', help='URL Domain (Ex: lte.int', required=True)
parser.add_argument('--mcc', help='mcc', required=True)
parser.add_argument('--mnc', help='mnc', required=True)
parser.add_argument('--tac', help='tac', required=True)
parser.add_argument('--amf', help='LTE Auth AMF', required=True)
parser.add_argument('--headless', action='store_true', help='Run in headless mode')

args = parser.parse_args()
organization = args.organization
organization_admin_user = args.organization_admin_user
organization_admin_password = args.organization_admin_password
domain = args.domain
network = args.network
network_id = args.network_id
mcc = args.mcc
mnc = args.mnc
tac = args.tac
amf = args.amf

tmout=2000
inst_tmout=20000
options = Options()

if args.headless:
    options.add_argument('-headless')

# Open browser:
driver = webdriver.Firefox(options=options)
driver.get(f"https://{organization}.nms.{domain}/admin/networks")

# Login:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div/div/div[2]/form/div[1]/li[1]/div/div[2]/div/div/input')).send_keys(organization_admin_user)
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div/div/div[2]/form/div[1]/li[2]/div/div[2]/div/div/input')).send_keys(organization_admin_password)
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div/div/div[2]/form/div[2]/button/span[1]')).click()

# Add network:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div/div/main/div[2]/div/div/div[1]/div/div[3]/div/div[1]/button/span[1]')).click()


# Network id:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[2]/div[3]/div/div[2]/div[1]/div/input')).send_keys(network_id)

# Network name:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[2]/div[3]/div/div[2]/div[2]/div/input')).send_keys(network)

# Network description:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[2]/div[3]/div/div[2]/div[3]/div/input')).send_keys(network)

# Neetwork type (click to get the options)
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[2]/div[3]/div/div[2]/div[4]/div/div')).click()

# Click in lte option:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/ul/li[4]/div/span')).click()

# Click in Save:
while True:
    try:
        WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[2]/div[3]/div/div[3]/button[2]/span[1]')).click()
        break
    except:
        time.sleep(1)


# Edit network:

driver.get(f"https://{organization}.nms.{domain}/nms/{network}/network/network")

# Edit
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div[2]/div/div[3]/div/div/div[1]/div[2]/button/span[1]')).click()

# amf
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[5]/div/div[2]/div/input')).clear()
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[5]/div/div[2]/div/input')).send_keys(amf)

# MCC
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[6]/div/div[2]/div/input')).clear()
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[6]/div/div[2]/div/input')).send_keys(mcc)

# MNC
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[7]/div/div[2]/div/input')).clear()
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[7]/div/div[2]/div/input')).send_keys(mnc)

# TAC
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[8]/div/div[2]/div/input')).clear()
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[3]/ul/li[8]/div/div[2]/div/input')).send_keys(tac)

# Save
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[3]/div[3]/div/div[4]/button[2]/span[1]')).click()

driver.close()
driver.quit()      