<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [1. Overview](#1-overview)
  - [1.1. Current Scenarios](#11-current-scenarios)
  - [1.2 Before You Begin](#12-before-you-begin)
- [2. How to Build and Run an NGINX Controller-Enabled NGINX Plus Image](#2-how-to-build-and-run-an-nginx-controller-enabled-nginx-plus-image)
  - [2.1. Building an NGINX Controller-Enabled Image with NGINX Plus](#21-building-an-nginx-controller-enabled-image-with-nginx-plus)
  - [2.2. Building a NAP-Enabled NGINX Docker Container](#22-building-a-nap-enabled-nginx-docker-container)
  - [2.3. Running an NGINX Controller-Enabled NGINX Docker Container](#23-running-an-nginx-controller-enabled-nginx-docker-container)
- [3.0 Adding a Controller Agent Layer to an Existing Container or Image](#30-adding-a-controller-agent-layer-to-an-existing-container-or-image)
  - [3.1 At Run Time](#31-at-run-time)
  - [3.2 As an Image Layer](#32-as-an-image-layer)
- [4.0 Build Time and Run Time Options](#40-build-time-and-run-time-options)
  - [4.1 Default Naming Behavior](#41-default-naming-behavior)
  - [4.2 Persisting an Instance Identity through Stops and Starts](#42-persisting-an-instance-identity-through-stops-and-starts)
  - [4.3 Applying a Unique Location to a Container at Run Time](#43-applying-a-unique-location-to-a-container-at-run-time)
- [5.0 Support](#50-support)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

We are actively working on improving support for containers with NGINX Controller.

The following is a set of guidelines that you can use today as we enhance the experience.

## 1. Overview

[NGINX Controller](https://www.nginx.com/products/nginx-controller/) is a centralized monitoring and management control-plane solution for the NGINX Plus data plane. NGINX Controller is developed and maintained by NGINX -- the people behind NGINX software.

With NGINX Controller, it is possible to collect and aggregate metrics across NGINX Plus instances, your applications, environments, and locations however they run -- presenting a coherent set of visualizations of the critical NGINX Plus performance data, such as active connections or requests per second. It is also easy to quickly check for any performance degradations and traffic anomalies and to get a more in-depth insight into the NGINX configuration in general.

A small agent (NGINX Controller Agent) is necessary inside the container alongside NGINX Plus to use NGINX Controller to monitor and/or manage your fleet of NGINX Plus instances.

For security protection of your web application, a web application firewall NGINX App Protect could be installed alongside NGINX Plus.
The official documentation for NGINX App Protect is available [here](https://docs.nginx.com/nginx-app-protect/).  

The official documentation for NGINX Controller is available [here](https://docs.nginx.com/nginx-controller/).

Guidance around NGINX Plus is available [here](https://www.nginx.com/blog/deploying-nginx-nginx-plus-docker/).

The Dockerfiles in this repository are supported by and tested against NGINX Controller v3.10 and later.

### 1.1. Current Scenarios

The following list summarizes known container scenarios with NGINX Controller:

- The NGINX [Controller Agent](https://docs.nginx.com/nginx-controller/admin-guides/install/install-nginx-controller-agent/) manages/monitors NGINX Plus from **inside the container**. It is not possible to run the Controller Agent in a separate container and monitor the neighboring containers running NGINX Plus, nor is it possible to install the Controller Agent on the container host and monitor/manage NGINX Plus running in containers.

### 1.2 Before You Begin

Before proceeding, first complete the following required steps:

1. [Install NGINX Controller](https://docs.nginx.com/nginx-controller/admin-guides/install/).
2. [Download your NGINX Plus certificate and key](https://docs.nginx.com/nginx-controller/admin-guides/install/get-n-plus-cert-and-key/) (that is, `nginx-repo.crt` and `nginx-repo.key`).
3. [Obtain the API key for your NGINX Controller instance](https://docs.nginx.com/nginx-controller/admin-guides/install/install-nginx-controller-agent/).

## 2. How to Build and Run an NGINX Controller-Enabled NGINX Plus Image

### 2.1. Building an NGINX Controller-Enabled Image with NGINX Plus

> **Note**: If you are new to Docker or the Dockerfile-based image building process, refer to the [Install Docker Engine](https://docs.docker.com/engine/install/) guide for installation instructions. See also the [Get started guide](https://docs.docker.com/get-started/) for instructions on obtaining and building images.

Here's how to build the container image with the Controller Agent inside, based on the official NGINX image:

1. Clone this repository:

    ```bash
    git clone https://github.com/nginxinc/docker-nginx-controller.git
    ```
    ```bash
    cd docker-nginx-controller/<distribution>/no-nap
    ```

2. Copy your NGINX Plus repository certificate and key to the folder of the Dockerfile you will be using for your Linux distribution.

3. Edit the Dockerfile with your API_KEY and CONTROLLER_URL.

    > Note: Use the `CONTROLLER_URL` format that's supported by your version of NGINX Controller:
    >
    > NGINX Controller v3.10 or older: `CONTROLLER_URL=https://<fqdn>:8443/1.4/install/controller`
    >
    > NGINX Controller v3.11 or newer: `CONTROLLER_URL=https://<fqdn>/install/controller-agent`

    For example:

    ```bash
    sudo docker build --build-arg CONTROLLER_URL=https://<fqdn>/install/controller-agent --build-arg API_KEY='abcdefxxxxxx' -t nginx-agent .
    ```

4. After the image is built, view the list of Docker images:

    ```bash
    sudo docker images
    ```

    The output looks similar to the following example:

    ```bash
    REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
    nginx-agent       latest              d039b39d2987        3 minutes ago       241.6 MB
    ```

### 2.2. Building a NAP-Enabled NGINX Docker Container

If you want your Docker image to include a web application firewall, in addition to the Controller Agent, 
use a Dockerfile with NGINX App Protect included. The file is located  at 
`docker-nginx-controller/<distribution>/nap`:

```bash
cd docker-nginx-controller/<distribution>/nap
```

### 2.3. Running an NGINX Controller-Enabled NGINX Docker Container

Take the following steps to run an NGINX Controller-enabled NGINX Docker Container:

1. To start a container from the new image, run the following command:

    ```bash
    docker run --name mynginx1 -d nginx-agent
    ```

2. After the container has started, check its status with `docker ps`:

    ```bash
    docker ps
    ```

    The output looks similar to the following example:

    ```bash
    CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
    7d7b47ba4c72        nginx-agent       "/entrypoint.sh"    3 seconds ago       Up 2 seconds        80/tcp, 443/tcp     mynginx1
    ```

3. You can also check the `docker logs` for the container status:

    ```bash
    docker logs 7d7b47ba4c72
    ```

    The output looks similar to the following example:

    ```bash
    starting nginx ...
    updating /etc/controller-agent/agent.conf ...
    ---> using api_key = 1234567890
    starting controller-agent ...
    ```

4. Check which processes have started:

    ```bash
    docker exec 7d7b47ba4c72 ps axu
    ```
    
    If you see the **controller-agent** process, the setup went smoothly, and you should see the new container in the NGINX Controller interface after approximately one minute.

    The output looks similar to the following example:

    ```bash
    USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
    root         1  0.0  0.1   4328   676 ?        Ss   19:33   0:00 /bin/sh /entrypoint.sh
    root         5  0.0  0.5  31596  2832 ?        S    19:33   0:00 nginx: master process nginx -g daemon off;
    nginx       11  0.0  0.3  31988  1968 ?        S    19:33   0:00 nginx: worker process
    nginx       65  0.6  9.1 111584 45884 ?        S    19:33   0:06 controller-agent
    ```

    If your container includes NAP (NGINX App Protect) then you should also see NAP-specific processes:

    ```bash
    nginx       10  0.0  2.5 129684 52320 ?        S    11:14   0:05 /usr/bin/perl /opt/app_protect/bin/bd_agent
    nginx       14  2.4 12.7 1057612 260260 ?      Sl   11:14   5:54 /usr/share/ts/bin/bd-socket-plugin tmm_count 4 proc_cpuinfo_cpu_m
    ```

5. To view the Controller Agent log, run the following command:

    ```bash
    docker exec 7d7b47ba4c72 tail /var/log/nginx-controller/agent.log
    ```

    The output looks similar to the following example:

    ```bash
    2016-08-05 19:49:39,001 [65] supervisor agent started, version=0.37-1 pid=65 uuid=<..>
    2016-08-05 19:49:39,047 [65] nginx_config running nginx -t -c /etc/nginx/nginx.conf
    2016-08-05 19:49:40,047 [65] supervisor post https://<controller url>:8443/<..>/ffeedd0102030405060708/agent/ 200 85 4 0.096
    2016-08-05 19:50:24,674 [65] bridge_manager post https://<controller url>:8443/<..>/ffeedd0102030405060708/update/ 202 2370 0 0.084
    ```

When you're done with the container, run the following command to stop it:

```bash
docker stop 7d7b47ba4c72
```

To check the status of all the containers that are running and stopped, run the following command:

```bash
docker ps -a
```

The output looks similar to the following example:

```bash
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                        PORTS               NAMES
7d7b47ba4c72        nginx-agent       "/entrypoint.sh"         22 minutes ago      Exited (137) 19 seconds ago                       mynginx1
```

## 3.0 Adding a Controller Agent Layer to an Existing Container or Image

An alternate way to handle the Controller Agent within containers is to include the necessary Controller Agent commands in the run command for an existing image. This way, you don't have to build the Controller Agent into your container before running, and you might find it handy for a Proof of Concept.

### 3.1 At Run Time

To add a Controller Agent layer to an existing container or image at run time, take the following steps:

```bash
# nginx-plus is an example base image located in debian/examples/nginx-plus
FROM nginx-plus

# Start a container with environment variables for CONTROLLER_URL and API_KEY
# docker run --name api-gw --hostname api-gw -e CONTROLLER_URL=https://<fqdn>/install/controller-agent -e API_KEY=deadbeef -d -P nginx-ctrl

# Install everything needed to install the Controller Agent so that the container can start quickly
RUN apt-get update &&\
        apt install -y \
        curl python gnupg2 procps dh-python distro-info-data libmpdec2 \
        libpython3-stdlib libpython3.5-minimal libpython3.5-stdlib \
        lsb-release python3 python3-minimal python3.5 python3.5-minimal \
        sudo

EXPOSE 80 443 8080
STOPSIGNAL SIGTERM

WORKDIR /controller

RUN printf "curl -skSL \$CONTROLLER_URL | bash -s - -y\n exec nginx -g 'daemon off;'" > start

CMD ["sh", "/controller/start"]
```

It takes 1-2 minutes to start the container. After `docker run `, use `docker logs --follow CONTAINER` to watch the installation and startup progress.

### 3.2 As an Image Layer

For your convenience, Dockerfiles that define a Controller Agent image layer are provided for you. These Dockerfiles are built following the pattern for [running multiple services in a Docker image](https://docs.docker.com/config/containers/multi-service_container) and can be found under each distribution in the following location:

```bash
cd docker-nginx-controller/<distribution>/examples/agent-layer
```

The build process is the same as above, referencing your custom image as the source.

## 4.0 Build Time and Run Time Options

### 4.1 Default Naming Behavior

By default, the Controller Agent determines the OS hostname during installation using the `hostname -f` command. The hostname value is then assigned to the `instance_name` key in the Controller Agent configuration file (`agent.conf`) and is used to generate a UUID. The UUID and instance name together provide a means of uniquely identifying the NGINX instance in NGINX Controller. When the Agent is run inside a container, the default hostname is a shortened Docker Container ID on the host. You can override the automatically assigned `instance_name` at run time by setting the `ENV_CONTROLLER_INSTANCE_NAME` environment variable to the desired value.

Providing the `ENV_CONTROLLER_INSTANCE_NAME` variable for the container sets the container's name that is displayed in NGINX Controller for the `displayName` of the instance. This also sets the instance object name, which is used in configuration references.

If you do not override the default instance name, the `containerID` is registered as the instance name and `displayName` in NGINX Controller.

### 4.2 Persisting an Instance Identity through Stops and Starts

Using the optional build-time setting of `STORE_UUID=True` ensures that the dynamically generated UUID persists in the Controller Agent configuration. This, together with the `instance_name`, allows the container instance to be stopped and started or persist if the container host is rebooted.

Each new container started from an NGINX Controller-enabled Docker image is reported as a unique system in the NGINX Controller console. This is the recommended configuration. NGINX Controller aggregates metrics across your instances based on the application, application component, location, environment, and so forth.

`VAR STORE_UUID=True` can be set during the image build process and applies to all containers derived from the image.

```bash
sudo docker build --build-arg CONTROLLER_URL=https://<fqdn>/install/controller-agent --build-arg API_KEY='abcdefxxxxxx' --build-arg STORE_UUID=True -t nginx-agent .
```

### 4.3 Applying a Unique Location to a Container at Run Time

By default, new instances are placed in the NGINX Controller location named `unspecified`. There are situations where instances should be associated with specific locations. This can be defined at build time to apply to all containers derived from the image or during run time and apply to a subset of containers.

Using the optional run time setting of `ENV_CONTROLLER_LOCATION`, when your container instance reports to NGINX Controller, the new instance will automatically register itself with a specific location already present in NGINX Controller.

```bash
docker run --name mynginx-east-1 -e ENV_CONTROLLER_LOCATION=east -d nginx-agent
```

The location will not be automatically created in NGINX Controller and needs to be defined separately.

### 4.4 Overriding Agent NGINX Controller configuration

Container could be build using configuration of one instance of NGINX Controller and run using another instance of NGINX Controller.
`ENV_CONTROLLER_API_KEY` and `ENV_CONTROLLER_API_URL` variable could be used to override during run-time NGINX Controller configuration.

```bash
docker run --name mynginx1 -d -e ENV_CONTROLLER_API_URL=https://<fqdn>:8443/1.4 -e ENV_CONTROLLER_API_KEY=deadbeef nginx-agent
```

(**Note**: RE: ENV_CONTROLLER_API_URL format

```bash
ENV_CONTROLLER_API_URL=https://<fqdn>:8443/1.4
```

### 4.5 Overriding NGINX Plus version

Version of NGINX Plus installed inside docker image could changed using `NGINX_PLUS_VERSION` build time argument.
`NGINX_PLUS_VERSION` should be set to release number of NGINX Plus e.g. `23`

```bash
docker build --build-arg CONTROLLER_URL=https://<fqdn>/install/controller-agent --build-arg API_KEY='abcdefxxxxxx' --build-arg NGINX_PLUS_VERSION=22 -t nginx-agent .
```

## 5.0 Support

This project is supported and has been validated with Controller Agent v3.10 and later.
