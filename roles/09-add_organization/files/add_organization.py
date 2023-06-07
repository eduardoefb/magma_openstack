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
parser.add_argument('--admin_user', help='Email for the admin user', required=True)
parser.add_argument('--admin_password', help='Password for the admin user', required=True)
parser.add_argument('--organization', help='Name of the organization', required=True)
parser.add_argument('--organization_admin_user', help='Name of the admin user for the organization', required=True)
parser.add_argument('--organization_admin_password', help='Name of the admin password for the organization', required=True)
parser.add_argument('--domain', help='URL Domain (Ex: lte.int', required=True)
parser.add_argument('--headless', action='store_true', help='Run in headless mode')

args = parser.parse_args()
admin_user = args.admin_user
admin_password = args.admin_password
organization = args.organization
organization_admin_user = args.organization_admin_user
organization_admin_password = args.organization_admin_password
domain = args.domain

tmout=2000
inst_tmout=20000
options = Options()

if args.headless:
    options.add_argument('-headless')

# Open browser:
driver = webdriver.Firefox(options=options)
driver.get(f"https://host.nms.{domain}")

# Login:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div/div/div[2]/form/div[1]/li[1]/div/div[2]/div/div/input')).send_keys(admin_user)
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div/div/div[2]/form/div[1]/li[2]/div/div[2]/div/div/input')).send_keys(admin_password)
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div/div/div[2]/form/div[2]/button/span[1]')).click()

# Add organization:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[1]/div/main/div/div/div[1]/button/span[1]')).click()

    
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[5]/div[3]/div/div[3]/ul/li[1]/div/div[2]/div/input')).send_keys(organization)
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[5]/div[3]/div/div[3]/ul/li[2]/button/span[1]')).click()
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[5]/div[3]/div/div[3]/ul/div/div/div/label/span[1]/span[1]/input')).click()

# Save:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[5]/div[3]/div/div[4]/button[2]/span[1]')).click()

# Check if organization is present:
if WebDriverWait(driver, 5).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[1]/div[2]/div/div/div/div/div/div[2]/span')):
    if WebDriverWait(driver, 5).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[1]/div[2]/div/div/div/div/div/div[2]/span')).text == "Request failed with status code 404":
        print("Organization already exists!")
        driver.close()
        driver.quit()
        exit(0)


# Organization admin user:
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[5]/div[3]/div/div[3]/ul/li[1]/div/div[2]/div/input')).send_keys(organization_admin_user)
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[5]/div[3]/div/div[3]/ul/li[2]/div/div[2]/div/input')).send_keys(organization_admin_password)
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[5]/div[3]/div/div[3]/ul/li[3]/div/div[2]/div/input')).send_keys(organization_admin_password)
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[5]/div[3]/div/div[3]/ul/li[4]/div/div[3]/div/div/div/span')).click()
WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[6]/div[3]/ul/li[3]/div/span')).click()

while True:
    try:
        WebDriverWait(driver,tmout).until(lambda driver: driver.find_element(By.XPATH, '/html/body/div[5]/div[3]/div/div[4]/button[2]/span[1]')).click()
        break
    except:
        time.sleep(1)

driver.close()
driver.quit()

   