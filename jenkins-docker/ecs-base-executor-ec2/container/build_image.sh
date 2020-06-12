#!/bin/bash -ex

apt-get update


# Docker
apt-get update && apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get update && apt-get install docker-ce docker-ce-cli containerd.io -y


# Install awscli
apt-get install -y python-pip
pip install awscli --upgrade

aws --version

apt-get install sudo -y
cp /tmp/container/90-cloud-init-users /etc/sudoers.d/90-cloud-init-users


#Install packer
# PACKER_ARCH="amd64"
# PACKER_INSTALL_DIR="/usr/local/bin/"
# PACKER_VERSION="1.5.4"
# PACKER_FILE_NAME="packer_${PACKER_VERSION}_linux_${PACKER_ARCH}.zip"
# PACKER_DOWNLOAD_URL="https://releases.hashicorp.com/packer/${PACKER_VERSION}/${PACKER_FILE_NAME}"
# mkdir -p ${PACKER_INSTALL_DIR} && \
#   cd ${PACKER_INSTALL_DIR} && \
#   curl -v ${PACKER_DOWNLOAD_URL} -o ${PACKER_FILE_NAME} && \
#   unzip ${PACKER_FILE_NAME} && \
#   cd - && \
#   packer -v


apt install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget -y
curl -O https://www.python.org/ftp/python/3.7.5/Python-3.7.5.tar.xz
tar -xf Python-3.7.5.tar.xz
cd Python-3.7.5
./configure
make altinstall

python3.7 -m pip install --upgrade pip

chown jenkins:jenkins /home/jenkins/.gitconfig
chmod 664 /home/jenkins/.gitconfig



# Teardown
rm -rvf /tmp/container/
