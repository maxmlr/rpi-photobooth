FROM php:7.3-fpm-alpine

# Install dev dependencies
RUN apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    curl-dev \
    imagemagick-dev \
    libtool \
    libxml2-dev \
    postgresql-dev \
    sqlite-dev

# Install production dependencies
RUN apk add --no-cache \
    bash \
    curl \
    g++ \
    gcc \
    git \
    imagemagick \
    libc-dev \
    libpng-dev \
    make \
    mysql-client \
    nodejs \
    nodejs-npm \
    yarn \
    openssh-client \
    postgresql-libs \
    rsync \
    zlib-dev \
    libzip-dev

# Install PECL and PEAR extensions
RUN pecl install \
    imagick \
    xdebug

# Install and enable php extensions
RUN docker-php-ext-enable \
    imagick \
    xdebug
RUN docker-php-ext-configure zip --with-libzip
RUN docker-php-ext-install \
    curl \
    exif \
    iconv \
    mbstring \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    pdo_sqlite \
    pcntl \
    tokenizer \
    xml \
    gd \
    zip \
    bcmath

# Install additional dependencies
RUN apk add --no-cache \
    shadow

# Cleanup dev dependencies
RUN apk del -f .build-deps

# correct www-data uid/gid
RUN usermod -u 101 www-data && \
    groupmod -g 101 www-data

# Make www-data user owner of /var/www
RUN chown www-data:www-data /var/www

# Install composer
WORKDIR /composer
RUN chown www-data:www-data /composer
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# get wait-for
RUN mkdir -p /usr/local/bin && \
 wget -O /usr/local/bin/wait-for https://raw.githubusercontent.com/eficode/wait-for/master/wait-for && \
 chmod +x /usr/local/bin/wait-for

# copy local app
COPY ./app /app

WORKDIR /app

# run setup if required
RUN /bin/sh /app/setup.sh

# copy php.ini
RUN mv /app/php.ini $PHP_INI_DIR/

# Switch to www-data user
USER www-data
RUN mkdir /var/www/laravel
ENV COMPOSER_HOME /composer
ENV PATH ./vendor/bin:/composer/vendor/bin:$PATH

# Install PHP_CodeSniffer
RUN composer global require "squizlabs/php_codesniffer=*"

# Install Laravel Installer
RUN composer global require laravel/installer

# Set working directory
WORKDIR /var/www/laravel

# Set Entrypoint and Cmd
ENTRYPOINT [ "/bin/sh", "/app/start.sh" ]
CMD 
