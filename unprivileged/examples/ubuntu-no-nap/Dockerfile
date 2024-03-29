# This dockerfile also support Ubuntu 16.04
# To use Ubuntu 16.04 replace base image with below one:
#FROM ubuntu:16.04
FROM ubuntu:18.04

LABEL maintainer="NGINX Controller Engineering"

# e.g '1234567890'
ARG API_KEY
ENV ENV_CONTROLLER_API_KEY=$API_KEY

# e.g https://<fqdn>/install/controller-agent
ARG CONTROLLER_URL
ENV ENV_CONTROLLER_URL=$CONTROLLER_URL

# e.g True or False
ARG STORE_UUID=False
ENV ENV_CONTROLLER_STORE_UUID=$STORE_UUID

# e.g Instance location already defined in Controller
ARG LOCATION
ENV ENV_CONTROLLER_LOCATION=$LOCATION

# e.g Instance group already defined in Controller
ARG INSTANCE_GROUP
ENV ENV_CONTROLLER_INSTANCE_GROUP=$INSTANCE_GROUP

# NGXIN Plus release e.g 24
ARG NGINX_PLUS_VERSION=24

ARG EXPOSE_PORT=8080
ENV NGINX_EXPOSE_PORT=$EXPOSE_PORT

ARG NON_ROOT_USER=nginx
ENV CONTROLLER_USER=$NON_ROOT_USER

ARG NON_ROOT_GROUP=nginx
ENV CONTROLLER_GROUP=$NON_ROOT_GROUP

ARG NAP_SYSLOG_PORT=5114
ENV LISTENERS_NAP_SYSLOG_PORT=$NAP_SYSLOG_PORT

COPY nginx-plus-api.conf /etc/nginx/conf.d/
COPY entrypoint.sh /

# Install NGINX Plus
RUN --mount=type=secret,id=nginx-crt,dst=/etc/ssl/nginx/nginx-repo.crt,mode=0644 \
  --mount=type=secret,id=nginx-key,dst=/etc/ssl/nginx/nginx-repo.key,mode=0644 \
  set -ex \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
  curl \
  sudo\
  vim\
  procps\
  gnupg\
  apt-utils\
  apt-transport-https\
  ca-certificates\
  distro-info-data\
  libmpdec2\
  lsb-release \
  binutils \
  net-tools \
  && apt-get upgrade -y \
  && \
  NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
  found=''; \
  for server in \
    ha.pool.sks-keyservers.net \
    hkp://keyserver.ubuntu.com:80 \
    hkp://p80.pool.sks-keyservers.net:80 \
    pgp.mit.edu \
  ; do \
    echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
    apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
  done; \
  test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
  echo "Acquire::https::plus-pkgs.nginx.com::Verify-Peer \"true\";" >> /etc/apt/apt.conf.d/90nginx \
  && echo "Acquire::https::plus-pkgs.nginx.com::Verify-Host \"true\";" >> /etc/apt/apt.conf.d/90nginx \
  && echo "Acquire::https::plus-pkgs.nginx.com::SslCert     \"/etc/ssl/nginx/nginx-repo.crt\";" >> /etc/apt/apt.conf.d/90nginx \
  && echo "Acquire::https::plus-pkgs.nginx.com::SslKey      \"/etc/ssl/nginx/nginx-repo.key\";" >> /etc/apt/apt.conf.d/90nginx \
  && printf "deb https://plus-pkgs.nginx.com/ubuntu $(lsb_release -cs) nginx-plus\n" > /etc/apt/sources.list.d/nginx-plus.list \
  # NGINX Javascript module needed for APIM
  && apt-get update && apt-get install -y nginx-plus=${NGINX_PLUS_VERSION}* nginx-plus-module-njs=${NGINX_PLUS_VERSION}*  \
  && rm -rf /var/lib/apt/lists/* \
  # Install Controller Agent
  && curl -k -sS -L ${CONTROLLER_URL} > install.sh \
  && sed -i 's/^assume_yes=""/assume_yes="-y"/' install.sh \
  && sed -i 's,-n "${NGINX_GPGKEY}",true,' install.sh \
  && sh ./install.sh -y \
  # cleanup sensitive nginx-plus data
  && rm /etc/apt/sources.list.d/nginx-plus.list \
  && rm /etc/apt/apt.conf.d/90nginx \
  && apt-key del "$NGINX_GPGKEY"

# Forward request logs to Docker log collector
RUN ln -sf /proc/1/fd/1 /var/log/nginx-controller/agent.log \
  && ln -sf /proc/1/fd/2 /var/log/nginx/error.log

# Update ownership for the necessary filesystem objects for running under non-root user
RUN chown -R $CONTROLLER_USER:$CONTROLLER_GROUP /var/run/ \
  && chown -R $CONTROLLER_USER:$CONTROLLER_GROUP /var/log/nginx/ \
  && chown -R $CONTROLLER_USER:$CONTROLLER_GROUP /var/cache/nginx/ \
  && chown -R $CONTROLLER_USER:$CONTROLLER_GROUP /etc/controller-agent/ \
  && chown -R $CONTROLLER_USER:$CONTROLLER_GROUP /etc/nginx/ \
  && chown -R $CONTROLLER_USER:$CONTROLLER_GROUP /var/log/app_protect/ || true \
  && chown -R $CONTROLLER_USER:$CONTROLLER_GROUP /opt/app_protect/ || true \
  && sed -i "s,listen       80 default_server;,listen       $NGINX_EXPOSE_PORT default_server;," /etc/nginx/conf.d/default.conf \
  && sed -i '/user  nginx;/d' /etc/nginx/nginx.conf

USER $CONTROLLER_USER

EXPOSE $NGINX_EXPOSE_PORT

STOPSIGNAL SIGTERM

ENTRYPOINT ["sh", "/entrypoint.sh"]
