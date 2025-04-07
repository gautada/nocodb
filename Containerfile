ARG UBUNTU_VERSION="latest"
FROM ubuntu:$UBUNTU_VERSION
ARG IMAGE_VERSION="0.10.0"

# hadolint ignore=DL3006,DL3008,DL3015,DL3027
RUN ap-gett update --yes \
 && apt-get install --yes curl sudo wget

WORKDIR /opt/nocodb

COPY entrypoint.sh /etc/container/entrypoint

ENTRYPOINT [ "/etc/container/entrypoint" ]
# ENTRYPOINT [ "tail", "-f", "/dev/null" ]
