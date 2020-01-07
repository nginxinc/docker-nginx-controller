
- [1. Overview](#1-overview)
  - [1.1. NGINX Controller Agent Inside Docker Container](#11-nginx-controller-agent-inside-docker-container)
  - [1.2. Standalone Mode](#12-standalone-mode)
  - [1.3. Current Limitations](#13-current-limitations)
- [2. How to Build and Run a Controller enabled NGINX image](#2-how-to-build-and-run-a-controller-enabled-nginx-image)
  - [2.1. Building a Controller-enabled image with NGINX](#21-building-a-controller-enabled-image-with-nginx)
  - [2.2. Running a Controller-enabled NGINX Docker Container](#22-running-a-controller-enabled-nginx-docker-container)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

We are actively working on improving support for Docker with NGINX Controller.
The following is a set of guidelines that you can use today as we enhance the experience.

## 1. Overview

[NGINX Controller](https://www.nginx.com/products/nginx-controller/) is a centralized monitoring and management control-plane solution for the NGINX data plane. Controller is developed and maintained by Nginx Inc. — the company behind the NGINX software.

With Controller it is possible to collect and aggregate metrics across NGINX instances and your applications however they run.  Presenting a coherent set of visualizations of the key NGINX performance data, such as active connections or requests per second. It is also easy to quickly check for any performance degradations, traffic anomalies, and get a deeper insight into the NGINX configuration in general.

In order to use Controller, a small Python-based agent software Controller Agent should be installed inside the container alongside NGINX Plus.

The official documentation for Controller is available [here](https://docs.nginx.com/nginx-controller/).

### 1.1. NGINX Controller Agent Inside Docker Container

The Controller Agent can be deployed in a Docker environment to monitor and / or configure NGINX processes inside Docker containers.
The agent can collect most of the metrics.

The "agent-inside-the-container" is currenly the only mode of operation. In other words, the agent should be running in the same container as the NGINX process being managed / monitored.
For more information, please refer to our [Controller Dockerfile repository](https://github.com/nginxinc/docker-nginx-controller.git).

### 1.2. Standalone Mode

By default the agent will try to determine the OS `hostname` on startup. The `hostname` is used to generate a UUID to uniquely identify the NGINX instance in NGINX Controller.  When the Agent is run inside of a container the hostname is the shortened Docker Container ID on the host where the container is running.

This means that each new container started from a Controller-enabled Docker image will be reported as a standalone system in the Controller Console.
This is the recommended configuration, as Controller will aggregate metrics across your instances based on the application, application component, location, environment, and so on.

If you prefer to assign the individual instances started from the same image as separatly named objects with more logical names, assign different `imagename` variable to each of the running instances.  And this will replace the automatically detected `hostname`.

You can learn more about the agent configuration options following the documentation link of your NGINX Controller.

  ```
  # If HOSTNAME is set, the startup wrapper script will use it to
  # generate the 'hostname' to put in the /etc/controller-agent/agent.conf
  # If IMAGENAME is set, the startup wrapper script will use it to
  # override the 'hostname' in the /etc/controller-agent/agent.conf

  # Each container must have a unique `hostname` and unique `imagename` for data to reflect correctly in Controller

  ENV HOSTNAME my-docker-instance-123
  
  # unique imagenames are useful when the automatically generated hostname overlaps between instances.
  ```

  or environment settings can be passed at contianer launch time:

- Use the `-e` option with `docker run` as in

  ```
  docker run --name mynginx1 -e API_KEY=1234567890 -e IMAGENAME=my-instance-123 -d nginx-agent
  ```

### 1.3. Current Limitations

The following list summarizes existing limitations of monitoring containers with NGINX Controller:

- The agent can only monitor NGINX from inside the container. It is not currently possible to run the agent in a separate container and monitor the neighboring containers running NGINX.

## 2. How to Build and Run a Controller enabled NGINX image

### 2.1. Building a Controller-enabled image with NGINX

(**Note**: If you are new to Docker, [here's](https://docs.docker.com/engine/installation/) how to install Docker Engine on various OS.)

**Note** Before proceeding, you must: install NGINX Controller, download your certificate and key for NGINX Plus, obtain the api key for your NGINX Contoller instance.

Here's how you can build the Docker image with the Contorller Agent inside, based on the official NGINX image:

```
git clone https://github.com/nginxinc/docker-nginx-controller.git
```

```
cd docker-nginx-controller
```

copy your NGINX Plus repositry certificate and key to the cloned folder.  
Edit the Dockerfile with your API_KEY and CONTROLLER_URL

```
docker build -t nginx-agent .
```

After the image is built, check the list of Docker images:

```
docker images
```

```
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
nginx-agent       latest              d039b39d2987        3 minutes ago       241.6 MB
```

### 2.2. Running a Controller-enabled NGINX Docker Container

To start a container from the new image, use the command below:

```
docker run --name mynginx1 -e API_KEY=1234567890 -d nginx-agent
```

The API_KEY is generated by your NGINX Controller
(optionally) For friendly names in Controller the IMAGENAME is set to identify the running service as described in sections 1.2 above.

After the container has started, you may check its status with `docker ps`:

```
docker ps
```

```
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
7d7b47ba4c72        nginx-agent       "/entrypoint.sh"    3 seconds ago       Up 2 seconds        80/tcp, 443/tcp     mynginx1
```

and you can also check `docker logs`:

```
docker logs 7d7b47ba4c72
```

```
starting nginx ...
updating /etc/controller-agent/agent.conf ...
---> using api_key = 1234567890
starting controller-agent ...
```

Check what processes have started:

```
docker exec 7d7b47ba4c72 ps axu
```

```
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.1   4328   676 ?        Ss   19:33   0:00 /bin/sh /entrypoint.sh
root         5  0.0  0.5  31596  2832 ?        S    19:33   0:00 nginx: master process nginx -g daemon off;
nginx       11  0.0  0.3  31988  1968 ?        S    19:33   0:00 nginx: worker process
nginx       65  0.6  9.1 111584 45884 ?        S    19:33   0:06 controller-agent
```

If you see the **controller-agent** process, it all went smoothly, and you should see the new container in the Controller interface in a minute or so.

Check the Controller Agent log:

```
docker exec 7d7b47ba4c72 tail /var/log/contorller-agent/agent.log
```

```
2016-08-05 19:49:39,001 [65] supervisor agent started, version=0.37-1 pid=65 uuid=<..>
2016-08-05 19:49:39,047 [65] nginx_config running nginx -t -c /etc/nginx/nginx.conf
2016-08-05 19:49:40,047 [65] supervisor post https://<controller url>:8443/<..>/ffeedd0102030405060708/agent/ 200 85 4 0.096
2016-08-05 19:50:24,674 [65] bridge_manager post https://<controller url>:8443/<..>/ffeedd0102030405060708/update/ 202 2370 0 0.084
```

When you're done with the container, you can stop it like the following:

```
docker stop 7d7b47ba4c72
```

To check the status of all containers (running and stopped):

```
docker ps -a
```

```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                        PORTS               NAMES
7d7b47ba4c72        nginx-agent       "/entrypoint.sh"         22 minutes ago      Exited (137) 19 seconds ago                       mynginx1
```

