# nginx-plus is an example base image located in debian/examples/nginx-plus
FROM nginx-plus

# Start container with environment variables for CONTROLLER_URL and API_KEY
# docker run --name apigw --hostname apigw -e CONTROLLER_URL=https://<fqdn>/install/controller-agent -e API_KEY=deadbeef -d -P nginx-ctrl

# Install everything we will need to install the Controller Agent so that the container can start quickly
RUN apt-get update &&\
        apt install -y \
        curl \
        gnupg2 \
        procps \
        distro-info-data \
        libmpdec2 \
        lsb-release sudo

EXPOSE 80 443 8080
STOPSIGNAL SIGTERM

WORKDIR /controller

# This script will download install and start the agent using `service controller-agent start` command.
# Agent service should be stopped gracefully using `service controller-agent stop` command, which
# is not done in this example as a solution strictly depends on the form of cmd/entrypoint of the base image.
# Example solution for multiple service management in docker image could be found in official docker
# documentation:
# https://docs.docker.com/config/containers/multi-service_container
RUN printf "curl -skSL \$CONTROLLER_URL | bash -s - -y\n exec nginx -g 'daemon off;'" > start

CMD ["sh", "/controller/start"]

