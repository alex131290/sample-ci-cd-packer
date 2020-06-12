FROM 561306761274.dkr.ecr.eu-west-1.amazonaws.com/jenkins-base-slave-ec2:3
ARG user=jenkins
USER root
LABEL description="This image includes cloudformation tools"
COPY container/install-cf-template.sh /usr/local/bin/install-cf-template
COPY container/install_packer.sh /tmp/container/install_packer.sh
RUN /bin/bash -ex /tmp/container/install_packer.sh
USER ${user}