#!/bin/bash -x
set -e

sudo apt-get update
sudo rm -rvf /var/lib/apt/lists/*

sudo add-apt-repository main
sudo add-apt-repository universe
sudo add-apt-repository restricted
sudo add-apt-repository multiverse

sudo apt-get update

sudo apt-get install -y \
    python2 \
    nginx \
    net-tools

# Install pip2
# This is needed for aws-cfn-bootstrap
curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py
sudo python2 get-pip.py

sudo pip2 install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz

sudo cp /home/$(whoami)/pkg/app/bin/app_linux64 /usr/local/bin/myapp
sudo chmod +x /usr/local/bin/myapp

sudo bash -c 'cat << EOF >> /etc/systemd/system/myapp.service
[Unit]
Description=myapp

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/myapp

[Install]
WantedBy=multi-user.target
'
sudo mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.disabled
sudo cp /home/$(whoami)/pkg/nginx/default /etc/nginx/sites-available/default
sudo nginx -t
sudo systemctl enable myapp.service 