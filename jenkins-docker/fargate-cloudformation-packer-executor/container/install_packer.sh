#!/bin/bash

# Install packer
PACKER_ARCH="amd64"
PACKER_INSTALL_DIR="/usr/local/bin/"
PACKER_VERSION="1.5.4"
PACKER_FILE_NAME="packer_${PACKER_VERSION}_linux_${PACKER_ARCH}.zip"
PACKER_DOWNLOAD_URL="https://releases.hashicorp.com/packer/${PACKER_VERSION}/${PACKER_FILE_NAME}"
mkdir -p ${PACKER_INSTALL_DIR} && \
  cd ${PACKER_INSTALL_DIR} && \
  curl -v ${PACKER_DOWNLOAD_URL} -o ${PACKER_FILE_NAME} && \
  unzip ${PACKER_FILE_NAME} && \
  cd - && \
  packer -v