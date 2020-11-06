FROM nginx-plus

# Install everything we will need to install the Controller Agent so that the container can start quickly
RUN yum update && yum -y install sudo procps ca-certificates gnupg wget binutils net-tools

EXPOSE 80 443 8080
STOPSIGNAL SIGTERM

WORKDIR /controller
# This script will download, install and start the agent using `/usr/bin/nginx-controller-agent`.
# Graceful shutdown of agent is not done in this example as this solution 
# strictly depends on the form of cmd/entrypoint of the base image.
# Example solution for multiple service management in docker image could be found in official docker
# documentation:
# https://docs.docker.com/config/containers/multi-service_container
# TODO: remove `sed` once launching agent using `service` has been handled in the install script
RUN printf "curl -skSL https://\$CTRL_HOST:8443/1.4/install/controller/ | sed '/^# Unconditionally stop the agent service/,\$d' | bash -s - -y\nexec nginx -g 'daemon off;' &\n/usr/bin/nginx-controller-agent" > start
CMD ["sh", "/controller/start"]
