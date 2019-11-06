# NGINX UNIT application server
This is custom build of NGINX UNIT application server based on alpine edge 
with pre-build unitd version. Also entrypoint script modified to enable timezone choosing.

[Alpine linux official website](https://alpinelinux.org/)

[NGINX UNIT official website](https://unit.nginx.org)

### What's included
This is `unit` application server with `php7` modules built in. 
> Follow modules included in this container:
* php7-embed
* php7-redis
* php7-apcu
* php7-bcmath
* php7-dom
* php7-ctype
* php7-curl
* php7-fileinfo
* php7-gd
* php7-iconv
* php7-intl
* php7-json
* php7-mbstring
* php7-mcrypt
* php7-mysqlnd
* php7-opcache
* php7-openssl
* php7-pdo
* php7-pdo_mysql
* php7-pdo_pgsql
* php7-pdo_sqlite
* php7-phar
* php7-posix
* php7-session
* php7-simplexml
* php7-soap
* php7-xml
* php7-zip
* php7-zlib
* php7-tokenizer
* [pinba](https://github.com/tony2001/pinba_extension)
* [composer](https://getcomposer.org/)

### How to use
#### Configuration options
Initial configuration is supported through `ENTRYPOINT` script. First, the script checks
`/var/lib/unit` state directory of the container and if it contains data all other actions will be ignored.
If state director **is empty**, then it start to scan `/docker-entrypoint.d/` for data of certain types:

|File type  |  Description/Purpose  |
|:---------:|:--------------------|
|.pem     |Certificate [bundles](https://unit.nginx.org/configuration/#configuration-ssl), uploaded under their respective names: `cert.pem` -> `certificates/cert`.|
|.json    |Configuration snippets, [uploaded](https://unit.nginx.org/configuration/#configuration-mgmt) to Unit as portions of the `config` section.|
|.sh      |Shell scripts, executed within the container after `.pem` and `.json` files are handled.|

For more information visit [official documentation](https://unit.nginx.org/configuration/).


Create directory `/unit/config` and put your config files, certificates or shell scripts there.
Run docker with folder mapping: 
```bash
docker run --rm -v /unit/config:/docker-entrypoint.d skovylov/nginx-unitd
```

#### Extra options
There is `UNIT_TZ` variable to define necessary timezone. By default, container uses **`UTC`** timezone,
so if you need set special zone or align time with host run follow command:

```bash
docker run --rm -e UNIT_TZ="Europe/Moscow" skovylov/nginx-unitd
```

All timezones can be found in `/usr/share/zoneinfo` on host server.

#### Log file
All logs are written to `/var/log/nginx/unitd.log`, if you need to redirect log file to host system, run follow:

```bash
docker run --rm -v /host/unit/log:/var/log/nginx skovylov/nginx-unitd
```

You will be able to see log entries on host machine under `/host/unit/log` directory.

#### PHP Composer
In addition to standard packages it's also added `composer`. You may add extra `php` packages 
via `.sh` script(s) using `composer` manager.