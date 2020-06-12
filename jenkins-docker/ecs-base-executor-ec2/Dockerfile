FROM jenkinsci/jnlp-slave:3.40-1
ARG user=jenkins
USER root
LABEL description="This image includes base tools for jenkins slave"
COPY container /tmp/container
RUN /bin/bash -ex /tmp/container/build_image.sh
USER ${user}
# ENTRYPOINT ["jenkins-slave"]


