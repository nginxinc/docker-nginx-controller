FROM centos:7

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

# NGXIN Plus release e.g 23
ARG NGINX_PLUS_VERSION=23

# Download certificate (nginx-repo.crt) and key (nginx-repo.key) from the customer portal (https://cs.nginx.com)
# and copy to the build context
COPY nginx-repo.* /etc/ssl/nginx/
COPY nginx-plus-api.conf /etc/nginx/conf.d/

# Install NGINX Plus
RUN set -ex \
  && yum -y update && yum -y upgrade \
  && yum -y install curl sudo vim procps ca-certificates gnupg wget binutils net-tools \
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
    gpg --keyserver "$server" --recv-keys "0x$NGINX_GPGKEY" && found=yes && break; \
  done; \
  test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
  wget -P /etc/yum.repos.d https://cs.nginx.com/static/files/nginx-plus-7.4.repo \
  # NGINX Javascript module needed for APIM
  && yum update && yum -y install nginx-plus-${NGINX_PLUS_VERSION}* nginx-plus-module-njs-${NGINX_PLUS_VERSION}*  \
  # Install Controller Agent
  && curl -k -sS -L ${CONTROLLER_URL} > install.sh \
  && sed -i 's/^assume_yes=""/assume_yes="-y"/' install.sh \
  # TODO: remove once launching agent using `service` has been handled in the install script
  && sed -i '/^# Unconditionally stop the agent service/,$d' install.sh \
  && sh ./install.sh -y \
  # cleanup sensitive nginx-plus data
  && rm /etc/ssl/nginx/nginx-repo.* \
  && rm /etc/yum.repos.d/nginx-plus-7.4.repo \
  && gpg --batch --delete-keys "$NGINX_GPGKEY"

# Forward request logs to Docker log collector
RUN ln -sf /proc/1/fd/1 /var/log/nginx-controller/agent.log \
  && ln -sf /proc/1/fd/2 /var/log/nginx/error.log

COPY entrypoint.sh /

# Update ownership for the necessary filesystem objects for running under "nginx" user
RUN chown -R nginx:nginx /var/run/ \
  && chown -R nginx:nginx /var/log/nginx/ \
  && chown -R nginx:nginx /var/log/nginx-controller/ \
  && chown -R nginx:nginx /var/cache/nginx/ \
  && chown -R nginx:nginx /etc/controller-agent/ \
  && chown -R nginx:nginx /etc/nginx/ \
  && sed -i 's,listen       80 default_server;,listen       8080 default_server;,' /etc/nginx/conf.d/default.conf \
  && sed -i '/user  nginx;/d' /etc/nginx/nginx.conf

USER nginx

EXPOSE 8080

STOPSIGNAL SIGTERM

ENTRYPOINT ["sh", "/entrypoint.sh"]
