FROM oldsmokegun/php-fpm:7.4.0

ENV NGINX_STABLE_VERSION_URL http://nginx.org/packages/debian

# nginx
RUN apt-get install -y \
    curl \
    gnupg2 \
    ca-certificates \
    lsb-release \
    && echo "deb $NGINX_STABLE_VERSION_URL `lsb_release -cs` nginx" | tee /etc/apt/sources.list.d/nginx.list \
    && curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - \
    && apt-key fingerprint ABF5BD827BD9BF62 \
    && apt-get update && apt-get install -y nginx \
    && apt-get autoclean && apt-get clean \
    && echo 'server {\n\
    listen          80;\n\
    server_name     localhost;\n\
    root            /usr/share/nginx/html;\n\
\n\
    location / {\n\    
        index  index.html index.htm index.php;\n\
    }\n\
\n\
    error_page   500 502 503 504  /50x.html;\n\
    location = /50x.html {\n\
        root   /usr/share/nginx/html;\n\
    }\n\
\n\
    location ~ \.php(.*)$ {\n\
        fastcgi_pass   127.0.0.1:9000;\n\
        fastcgi_index  index.php;\n\
        fastcgi_split_path_info  ^((?U).+\.php)(/?.+)$;\n\
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;\n\
        fastcgi_param  PATH_INFO  $fastcgi_path_info;\n\
        fastcgi_param  PATH_TRANSLATED  $document_root$fastcgi_path_info;\n\
        include        fastcgi_params;\n\
    }\n\
}' > /etc/nginx/conf.d/default.conf

# supervisor
RUN apt-get install supervisor -y \
    && apt-get autoclean && apt-get clean \
    && sed -i '/\[supervisord\]/ a\nodaemon=true' /etc/supervisor/supervisord.conf \
    && touch /etc/supervisor/conf.d/nginx.conf \
    && echo '[program:nginx]\n\
command=nginx -g "daemon off;"' > /etc/supervisor/conf.d/nginx.conf \
    && touch /etc/supervisor/conf.d/php-fpm.conf \
    && echo '[program:php-fpm]\n\
command=php-fpm' > /etc/supervisor/conf.d/php-fpm.conf

RUN mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.php \
    && echo '<?php var_dump(phpinfo());' > /usr/share/nginx/html/index.php

EXPOSE 80 443

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]