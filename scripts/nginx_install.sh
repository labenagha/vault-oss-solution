#!/bin/bash
# For testing

exec > >(sudo tee -a /var/log/install_install.log) 2>&1

sudo apt-get update
sudo apt-get install -y nginx
