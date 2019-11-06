FROM alpine:edge

LABEL maintainer="SVK <docker-builds@skovylov.ru>"

RUN rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \
    && apk update \
    && apk add --no-cache --update \
        php7 \
        php7-embed \
        php7-redis \
        php7-apcu \
        php7-bcmath \
        php7-dom \
        php7-ctype \
        php7-curl \
        php7-fileinfo \
        php7-gd \
        php7-iconv \
        php7-intl \
        php7-json \
        php7-mbstring \
        php7-mcrypt \
        php7-mysqlnd \
        php7-opcache \
        php7-openssl \
        php7-pdo \
        php7-pdo_mysql \
        php7-pdo_pgsql \
        php7-pdo_sqlite \
        php7-phar \
        php7-posix \
        php7-session \
        php7-simplexml \
        php7-soap \
        php7-xml \
        php7-zip \
        php7-zlib \
        php7-tokenizer \
        unit \
        unit-php7 \
        curl \
        tzdata \
        composer \
        bash 

# Add pinba plugin
RUN apk add --no-cache --virtual .build \
    php7-dev \
    git \
    build-base \
    gcc \
    re2c \
    && cd /tmp \
    && git clone https://github.com/tony2001/pinba_extension.git \
    && cd pinba_extension \
    && phpize \
    && ./configure --enable-pinba \
    && make install \
    && apk del .build \
    && cd /tmp \
    && rm -rf pinba_extension \
    && echo "extension=pinba.so" > /etc/php7/conf.d/01_pinba.ini


STOPSIGNAL SIGTERM

COPY docker-entrypoint.sh /usr/local/bin/
COPY helpers /usr/share/helpers

RUN mkdir /docker-entrypoint.d/ \
    && mkdir /var/log/nginx

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock", "--log", "/var/log/nginx/unitd.log"]
