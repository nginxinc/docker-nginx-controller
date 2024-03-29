# Example nginx-plus only Dockerfile
FROM ubuntu:18.04

LABEL maintainer="NGINX Docker Maintainers <docker-maint@nginx.com>"

# Install NGINX Plus
RUN --mount=type=secret,id=nginx-crt,dst=/etc/ssl/nginx/nginx-repo.crt,mode=0644 \
 --mount=type=secret,id=nginx-key,dst=/etc/ssl/nginx/nginx-repo.key,mode=0644 \
 set -x \
 && apt-get update && apt-get upgrade -y \
 && apt-get install --no-install-recommends --no-install-suggests -y apt-transport-https ca-certificates gnupg1 procps wget curl vim \
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
   apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys     "$NGINX_GPGKEY" && found=yes && break; \
 done; \
 test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
 echo "Acquire::https::plus-pkgs.nginx.com::Verify-Peer \"true\";" >> /etc/apt/apt.conf.d/90nginx \
 && echo "Acquire::https::plus-pkgs.nginx.com::Verify-Host \"true\";" >> /etc/apt/apt.conf.d/90nginx \
 && echo "Acquire::https::plus-pkgs.nginx.com::SslCert     \"/etc/ssl/nginx/nginx-repo.crt\";" >> /etc/apt/apt.conf.d/90nginx \
 && echo "Acquire::https::plus-pkgs.nginx.com::SslKey      \"/etc/ssl/nginx/nginx-repo.key\";" >> /etc/apt/apt.conf.d/90nginx \
 && printf "deb https://plus-pkgs.nginx.com/ubuntu bionic nginx-plus\n" > /etc/apt/sources.list.d/nginx-plus.list \
 && apt-get update && apt-get install -y nginx-plus \
 && apt-get remove --purge --auto-remove -y gnupg1 \
 && rm -rf /var/lib/apt/lists/*

# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
