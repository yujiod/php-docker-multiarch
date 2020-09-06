FROM debian:buster-slim AS builder

# Download QEMU, see https://github.com/docker/hub-feedback/issues/1261
ENV QEMU_URL https://github.com/balena-io/qemu/releases/download/v3.0.0%2Bresin/qemu-3.0.0+resin-aarch64.tar.gz
RUN curl -L ${QEMU_URL} | tar zxvf - -C . --strip-components 1

ARG TAG
FROM arm64v8/php:${TAG:-}

# Add QEMU
COPY --from=builder qemu-aarch64-static /usr/bin

RUN apt-get update && apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev libzip-dev git unzip libicu-dev libzstd-dev libpq-dev \
    && docker-php-ext-configure gd ${GD_OPT} \
    && docker-php-ext-configure zip ${ZIP_OPT} \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql zip pcntl bcmath intl pdo_pgsql \
    && yes | pecl install igbinary redis \
    && docker-php-ext-enable opcache igbinary redis \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer config -g repos.packagist composer https://packagist.jp && \
    composer global require hirak/prestissimo
