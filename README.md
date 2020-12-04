
- [1. Overview](#1-overview)
  - [1.1. NGINX Controller Agent Inside Docker Container](#11-nginx-controller-agent-inside-docker-container)
  - [1.2. Standalone Mode](#12-standalone-mode)
  - [1.3. Current Limitations](#13-current-limitations)
- [2. How to Build and Run a Controller enabled NGINX image](#2-how-to-build-and-run-a-controller-enabled-nginx-image)
  - [2.1. Building a Controller-enabled image with NGINX](#21-building-a-controller-enabled-image-with-nginx)
  - [2.2. Running a Controller-enabled NGINX Docker Container](#22-running-a-controller-enabled-nginx-docker-container)
- [3.0 Adding agent during container run](#30-adding-agent-during-container-run)
- [Support](#support)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

We are actively working on improving support for Docker with NGINX Controller.

The following is a set of guidelines that you can use today as we enhance the experience.

## 1. Overview

[NGINX Controller](https://www.nginx.com/products/nginx-controller/) is a centralized monitoring and management control-plane solution for the NGINX data plane. NGINX Controller is developed and maintained by NGINX Inc. —- the company behind the NGINX software.

With NGINX Controller, it is possible to collect and aggregate metrics across NGINX instances and your applications however they run —- presenting a coherent set of visualizations of the critical NGINX performance data, such as active connections or requests per second. It is also easy to quickly check for any performance degradations and traffic anomalies and to get a more in-depth insight into the NGINX configuration in general.

A small Python-based agent software NGINX Controller Agent should be installed inside the container alongside NGINX Plus to use NGINX Controller.

The official documentation for NGINX Controller is available [here](https://docs.nginx.com/nginx-controller/).

Guidance around NGINX Plus is available [here](https://www.nginx.com/blog/deploying-nginx-nginx-plus-docker/).

Dockerfiles contained in this repository are supported by and tested against NGINX Controller version 3.10 and later.
Note: When building NGINX Plus into a container, be sure to remove repository credentials from your container.

### 1.1. NGINX Controller Agent Inside Docker Container

The Controller Agent can be deployed in a Docker environment to monitor and/or configure NGINX processes inside Docker containers.
The Controller Agent can collect most of the metrics.

The "agent-inside-the-container" is currently the only mode of operation. In other words, the Controller Agent should be running in the same container as the NGINX process being managed/monitored.
For more information, please refer to our [Controller Dockerfile repository](https://github.com/nginxinc/docker-nginx-controller.git).

### 1.2. Standalone Mode

By default, the Controller Agent will determine the OS hostname during installation using the `hostname -f` command. The hostname value will then be assigned to the `instance_name` key in the Controller Agent configuration file (`agent.conf`) and further used to generate a UUID, which together with an instance name provide a means of uniquely identifying the NGINX instance in NGINX Controller. When the Agent is run inside a container, the default hostname is a shortened Docker Container ID on the host. You can override the automatically assigned `instance_name` on runtime by setting the `ENV_CONTROLLER_INSTANCE_NAME` environment variable to the desired value. 

Using the optional build-time setting of `STORE_UUID=True` will also ensure that the dynamically generated UUID is persisted in the Controller Agent configuration. This, together with the `instance_name`, allows the container instance to be stopped and started or persist if the container host is rebooted.

Each new container started from an NGINX Controller-enabled Docker image is reported as a standalone system in the NGINX Controller console. This is the recommended configuration, as NGIN Controller will aggregate metrics across your instances based on the application, application component, location, environment, and so forth.

To learn more about the NGINX Agent configuration options, refer to the NGINX Controller documentation by selecting the help link in NGINX Controller.

```bash
# If HOSTNAME is set, the startup wrapper script will use it to
# generate the 'hostname' to put in the /etc/controller-agent/agent.conf

ENV HOSTNAME my-docker-instance-123

```

Alternatively, environment settings can be passed at the container launch time. Use the `-e` option with `docker run`, for example:

```bash
docker run --name mynginx1 -e ENV_CONTROLLER_API_KEY=1234567890 -e ENV_CONTROLLER_INSTANCE_NAME=my-instance-123 -d nginx-agent
```

### 1.3. Current Limitations

The following list summarizes the existing limitations of monitoring containers with NGINX Controller:

- The Controller Agent can only monitor NGINX from inside the container. It is not currently possible to run the Controller Agent in a separate container and monitor the neighboring containers running NGINX.

## 2. How to Build and Run an NGINX Controller-enabled NGINX image

### 2.1. Building an NGINX Controller-enabled image with NGINX

(**Note**: If you are new to Docker, refer to the documentation on [how to install Docker Engine on various operating systems](https://docs.docker.com/engine/installation/).)

**Before You Begin** Before proceeding, you must [install NGINX Controller](https://docs.nginx.com/nginx-controller/admin-guides/install/), [download your NGINX Plus certificate and key](https://docs.nginx.com/nginx-controller/admin-guides/install/get-n-plus-cert-and-key/) (that is, `nginx-repo.crt` and `nginx-repo.key`), and [obtain the API key for your NGINX Controller instance](https://docs.nginx.com/nginx-controller/api/overview/).

Here's how to build the Docker image with the Controller Agent inside, based on the official NGINX image:

```bash
git clone https://github.com/nginxinc/docker-nginx-controller.git
```

```bash
cd docker-nginx-controller/<os>
```

Copy your NGINX Plus repository certificate and key to the cloned folder.  
Edit the Dockerfile with your API_KEY and ENV_CONTROLLER_URL

```bash
# If NGINX Controller version is 3.10 or older
docker build --build-arg CONTROLLER_URL=https://<fqdn>:8443/1.4/install/controller/ --build-arg API_KEY='abcdefxxxxxx' -t nginx-agent .

# If NGINX Controller version is 3.11 or newer
docker build --build-arg CONTROLLER_URL=https://<fqdn>/install/controller-agent --build-arg API_KEY='abcdefxxxxxx' -t nginx-agent .
```

After the image is built, check the list of Docker images:

```bash
docker images
```

```bash
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx-agent       latest              d039b39d2987        3 minutes ago       241.6 MB
```

Alternately, you can set the VAR STORE_UUID=True during the image build process. This has the effect of persisting the instance displayName in NGINX Controller through container stop and start actions. The displayName will default to the hostname of the machine.

```bash
# If NGINX Controller version is 3.10 or older
sudo docker build --build-arg CONTROLLER_URL=https://<fqdn>:8443/1.4/install/controller/ --build-arg API_KEY='abcdefxxxxxx' --build-arg STORE_UUID=True -t nginx-agent .

# If NGINX Controller version is 3.11 or newer
sudo docker build --build-arg CONTROLLER_URL=https://<fqdn>/install/controller-agent --build-arg API_KEY='abcdefxxxxxx' --build-arg STORE_UUID=True -t nginx-agent .
```

### 2.2. Running an NGINX Controller-enabled NGINX Docker Container

To start a container from the new image, run the following command:

```bash
docker run --name mynginx1 -e ENV_CONTROLLER_INSTANCE_NAME=mynginx1 -d nginx-agent
```

Providing the `ENV_CONTROLLER_INSTANCE_NAME` variable for the container sets the container's name that is displayed in NGINX Controller for the displayName of the instance. This also sets the instance object name, which is used in configuration references.

If you do not override the default instance name, the containerID is registered as the instance name and displayName within NGINX Controller.

After the container has started, you can check its status with `docker ps`:

```bash
docker ps
```

```bash
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
7d7b47ba4c72        nginx-agent       "/entrypoint.sh"    3 seconds ago       Up 2 seconds        80/tcp, 443/tcp     mynginx1
```

You can also check the `docker logs`:

```bash
docker logs 7d7b47ba4c72
```

```bash
starting nginx ...
updating /etc/controller-agent/agent.conf ...
---> using api_key = 1234567890
starting controller-agent ...
```

Check which processes have started:

```bash
docker exec 7d7b47ba4c72 ps axu
```

```bash
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.1   4328   676 ?        Ss   19:33   0:00 /bin/sh /entrypoint.sh
root         5  0.0  0.5  31596  2832 ?        S    19:33   0:00 nginx: master process nginx -g daemon off;
nginx       11  0.0  0.3  31988  1968 ?        S    19:33   0:00 nginx: worker process
nginx       65  0.6  9.1 111584 45884 ?        S    19:33   0:06 controller-agent
```

If you see the **controller-agent** process, the setup went smoothly, and you should see the new container in the NGINX Controller interface after approximately one minute.

To check the Controller Agent log:

```bash
docker exec 7d7b47ba4c72 tail /var/log/nginx-controller/agent.log
```

```bash
2016-08-05 19:49:39,001 [65] supervisor agent started, version=0.37-1 pid=65 uuid=<..>
2016-08-05 19:49:39,047 [65] nginx_config running nginx -t -c /etc/nginx/nginx.conf
2016-08-05 19:49:40,047 [65] supervisor post https://<controller url>:8443/<..>/ffeedd0102030405060708/agent/ 200 85 4 0.096
2016-08-05 19:50:24,674 [65] bridge_manager post https://<controller url>:8443/<..>/ffeedd0102030405060708/update/ 202 2370 0 0.084
```

When you're done with the container, run the following command to step it:

```bash
docker stop 7d7b47ba4c72
```

To check the status of all the containers that are running and stopped, run the following command:

```bash
docker ps -a
```

```bash
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                        PORTS               NAMES
7d7b47ba4c72        nginx-agent       "/entrypoint.sh"         22 minutes ago      Exited (137) 19 seconds ago                       mynginx1
```

## 3.0 Adding the Controller Agent during container run

An alternate way to handle the Controller Agent within containers is to include the necessary Controller Agent commands in the run command for the container. This way, you don't have to build the Controller Agent into your container before running.

Alternate Dockerfile

```bash
# nginx-plus is an example base image located in debian/examples/nginx-plus
FROM nginx-plus

# Start container with environment variables for CTRL_HOST and API_KEY
# docker run --name apigw --hostname apigw -e CTRL_HOST=10.20.30.40 -e API_KEY=deadbeef -d -P nginx-ctrl

# Install everything we will need to install the Controller Agent so that the container can start quickly
RUN apt-get update &&\
        apt install -y \
        curl python gnupg2 procps dh-python distro-info-data libmpdec2 \
        libpython3-stdlib libpython3.5-minimal libpython3.5-stdlib \
        lsb-release python3 python3-minimal python3.5 python3.5-minimal \
        sudo

EXPOSE 80 443 8080
STOPSIGNAL SIGTERM

WORKDIR /controller

# This script will download, install, and start the Controller Agent using the `service controller-agent start` command.
# The Controller Agent service should be stopped gracefully using `service controller-agent stop` command, which
# is not done in this example as a solution strictly depends on the form of cmd/entry point of the base image.
# Example solution for multiple service management in docker image could be found in official docker
# documentation:
# https://docs.docker.com/config/containers/multi-service_container
RUN printf "curl -skSL https://\$CTRL_HOST:8443/1.4/install/controller/ | bash -s - -y\n exec nginx -g 'daemon off;'" > start

CMD ["sh", "/controller/start"]
```

It takes 1-2 minutes to start the container. After `docker run `, use `docker logs --follow CONTAINER` to watch the install/startup progress.
A working alternative and `nginx-plus` example Dockerfiles can be found here:

- debian/examples/
- centos/examples/

## Support

This project is not covered by the NGINX Plus support contract.

This project is currently considered *experimental* and has been validated with Controller Agent 2.8+, and was adapted from the Amplify guidance.