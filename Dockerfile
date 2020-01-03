FROM oldsmokegun/php-fpm:7.4.0

ENV NGINX_VERSION 1.17.1
ENV NGINX_INSTALLATION_PATH /usr/local/nginx

# nginx
RUN apt-get install -y \
    zlib1g \
    zlib1g-dev \
    libpcre3 \
    libpcre3-dev \
    openssl \
    libssl-dev \
    wget \
    && apt-get autoclean && apt-get clean \
    && cd /opt \
    && wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
    && tar -xvf nginx-$NGINX_VERSION.tar.gz \
    && cd nginx-$NGINX_VERSION \
    && ./configure \
        --prefix=$NGINX_INSTALLATION_PATH \
        --sbin-path=$NGINX_INSTALLATION_PATH/sbin/nginx \
        --conf-path=$NGINX_INSTALLATION_PATH/conf.d/nginx.conf \
        --pid-path=$NGINX_INSTALLATION_PATH/logs/nginx.pid \
        --error-log-path=$NGINX_INSTALLATION_PATH/logs/error.log \
        --http-log-path=$NGINX_INSTALLATION_PATH/logs/access.log \
        --with-http_ssl_module \
    && make && make install \
    && rm -rf /opt/nginx-$NGINX_VERSION.tar.gz \
    && echo 'user  nginx;\n\
worker_processes  1;\n\
\n\
error_log  /var/log/nginx/error.log warn;\n\
pid        /var/run/nginx.pid;\n\
\n\
events {\n\
    worker_connections  1024;\n\
}\n\
\n\
http {\n\
    include       mime.types;\n\
    default_type  application/octet-stream;\n\
\n\
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '\n\
                    '$status $body_bytes_sent "$http_referer" '\n\
                    '"$http_user_agent" "$http_x_forwarded_for"';\n\
\n\
    access_log  /var/log/nginx/access.log  main;\n\
\n\
    sendfile        on;\n\
    #tcp_nopush     on;\n\
\n\
    keepalive_timeout  65;\n\
\n\
    #gzip  on;\n\
\n\
    include vhosts/*.conf;\n\
}' > $NGINX_INSTALLATION_PATH/conf.d/nginx.conf \
    && mkdir $NGINX_INSTALLATION_PATH/conf.d/vhosts \
    && touch $NGINX_INSTALLATION_PATH/conf.d/vhosts/default.conf \
    && echo 'server {\n\
    listen       80;\n\
    root   "/www/wwwroot";\n\
    location / {\n\
        index  index.html index.htm index.php;\n\
        #autoindex  on;\n\
        try_files $uri $uri/ /index.php?$query_string;\n\
    }\n\
    location ~ \.php(.*)$ {\n\
        fastcgi_pass   127.0.0.1:9000;\n\
        fastcgi_index  index.php;\n\
        fastcgi_split_path_info  ^((?U).+\.php)(/?.+)$;\n\
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;\n\
        fastcgi_param  PATH_INFO  $fastcgi_path_info;\n\
        fastcgi_param  PATH_TRANSLATED  $document_root$fastcgi_path_info;\n\
        include        fastcgi_params;\n\
    }\n\
}' > $NGINX_INSTALLATION_PATH/conf.d/vhosts/default.conf \
    && mkdir /var/log/nginx/ \
    && useradd nginx

# supervisor
RUN apt-get install supervisor -y \
    && apt-get autoclean && apt-get clean \
    && sed -i '/\[supervisord\]/ a\nodaemon=true' /etc/supervisor/supervisord.conf \
    && touch /etc/supervisor/conf.d/nginx.conf \
    && echo '[program:nginx]\n\
command=/usr/local/nginx/sbin/nginx -g "daemon off;" -c /usr/local/nginx/conf.d/nginx.conf' > /etc/supervisor/conf.d/nginx.conf \
    && touch /etc/supervisor/conf.d/php-fpm.conf \
    && echo '[program:php-fpm]\n\
command=php-fpm' > /etc/supervisor/conf.d/php-fpm.conf

WORKDIR /www/wwwroot

RUN touch /www/wwwroot/index.php \
    && echo '<?php var_dump(phpinfo());' > /www/wwwroot/index.php

EXPOSE 80 443

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]