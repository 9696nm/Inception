FROM alpine:3.19

RUN apk update && \
    apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-dom \
    php83-gd \
    php83-xml \
    php83-xmlreader \
    php83-mbstring \
    php83-curl \
    php83-zip \
    php83-opcache \
    wget && \
    
    wget https://wordpress.org/latest.tar.gz -O wordpress.tar.gz && \
    tar -xzf wordpress.tar.gz -C /var/www/html --strip-components=1 && \
    rm wordpress.tar.gz && \
    
    chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    
    # Configure php-fpm
    mv /etc/php83/php-fpm.d/www.conf /etc/php83/php-fpm.d/www.conf.bak && \
    cp /etc/php83/php-fpm.conf /etc/php83/php-fpm.conf.bak && \
    
    echo "[www]
user = www-data
group = www-data
listen = 9000
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
" > /etc/php83/php-fpm.d/www.conf

EXPOSE 9000

CMD ["php-fpm83", "-F"]
