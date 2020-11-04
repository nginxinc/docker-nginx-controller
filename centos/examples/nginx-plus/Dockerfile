FROM centos:7

LABEL maintainer="NGINX Controller Engineering"

# Download certificate and key from the customer portal (https://cs.nginx.com)
# and copy to the build context
COPY nginx-repo.crt /etc/ssl/nginx/
COPY nginx-repo.key /etc/ssl/nginx/
# Install NGINX Plus
RUN set -ex \
  && yum -y update && yum -y upgrade \
  && yum -y install sudo procps ca-certificates gnupg wget binutils net-tools \
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
  && yum update && yum -y install nginx-plus nginx-plus-module-njs
 
# Forward request logs to Docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log
  
EXPOSE 80
STOPSIGNAL SIGTERM

COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
