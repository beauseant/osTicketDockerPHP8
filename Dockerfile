#FROM php:7.3-apache
FROM php:8.2-apache

LABEL MAINTAINER="Vincent Hindriksen"



ENV APPHOST http://localhost:80
ENV APPHTTPS false

ARG DATABASE_NAME=osticket
ARG DATABASE_USERNAME=osticket
ARG DATABASE_PASSWORD=osticket
ARG DATABASE_HOST=osticket

ENV env_DATABASE_NAME=${DATABASE_NAME}
ENV env_DATABASE_USERNAME=${DATABASE_USERNAME}
ENV env_DATABASE_PASSWORD ${DATABASE_PASSWORD}
ENV env_DATABASE_HOST ${DATABASE_HOST}


RUN apt-get update && \
    apt-get install -y --install-recommends \
    curl \
    nano \
    cron \
    libzip-dev \
    libz-dev \
    libssl-dev \
    libxml2-dev \
    libmcrypt-dev \
    libc-client-dev \
    libkrb5-dev

# Install gd
# RUN apt-get install -y \
#         libfreetype6-dev \
#         libjpeg62-turbo-dev \
#         libpng-dev \
#     && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
#     && docker-php-ext-install gd

RUN set -ex; \
  apt-get install --no-install-recommends -y \
    libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j$(nproc) gd
# Install APCu
RUN pecl install apcu \
    && docker-php-ext-enable apcu

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN pecl config-set php_ini "$PHP_INI_DIR/php.ini"
RUN ls -l "$PHP_INI_DIR/"
#RUN ls -l /usr/src/php/ext/

# # Install the PHP mcrypt extention
# RUN pecl install mcrypt-1.0.4 \
#    && echo "extension=mcrypt.so" > "$PHP_INI_DIR/php.ini"
# # RUN docker-php-ext-install mcrypt
# Install mbstring
#RUN docker-php-ext-install mbstring
# Install xml
RUN docker-php-ext-install xml
# Install fileinfo
RUN docker-php-ext-install fileinfo
# Install the PHP pdo_mysql extention
RUN docker-php-ext-install mysqli \
    && docker-php-ext-install pdo_mysql
# Install zip
RUN apt-get install -y \
        zlib1g-dev \
    && docker-php-ext-install zip
# Install imap
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
        && docker-php-ext-install imap \
        && docker-php-ext-enable imap
# Install Intl
RUN docker-php-ext-install intl
# Install Zend OPcache
RUN docker-php-ext-install opcache 

# Cleaning up
RUN pecl clear-cache

# Copy app code
COPY build /var/www/html/
# Copy error for DEBUG
COPY build/error.ini  /usr/local/etc/php/conf.d/

#SETUP DE DATABASE:
#ENV DATABASE_NAME osticket
#ENV DATABASE_USERNAME osticket
#ENV DATABASE_PASSWORD osticket

RUN sed -i -e "s/define('DBNAME','osticket');/define('DBNAME','${env_DATABASE_NAME}');/g"  /var/www/html/include/ost-config.php
RUN sed -i -e "s/define('DBHOST','mysql_osticket.local');/define('DBHOST','${env_DATABASE_HOST}');/g" /var/www/html/include/ost-config.php
RUN sed -i -e "s/define('DBUSER','osticket');/define('DBUSER','${env_DATABASE_USERNAME}');/g" /var/www/html/include/ost-config.php
RUN sed -i -e "s/define('DBPASS','osticket');/define('DBPASS','${env_DATABASE_PASSWORD}');/g" /var/www/html/include/ost-config.php


# Configure cron job
# Add crontab file in the cron directory
RUN crontab /var/www/html/crontab
# Create the log file to be able to run tail
RUN touch /var/log/cron.log
# Reload cron
RUN service cron reload

# Enable Apache mod_rewrite
RUN a2enmod rewrite
# Change Apache User
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
# Bind Apache User with our User
RUN usermod --non-unique --uid 1000 www-data
RUN groupmod --non-unique --gid 1000 www-data

VOLUME ["/var/www/html/storage", "/var/www/html/custom"]

CMD /var/www/html/init_storage.sh; cron; apache2-foreground

EXPOSE 80
