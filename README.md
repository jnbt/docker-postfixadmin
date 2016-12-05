# Roundcube on alpine:3.4

[![docker hub](https://img.shields.io/badge/docker-image-blue.svg?style=flat-square)](https://registry.hub.docker.com/u/jnbt/postfixadmin/)
[![imagelayers](https://badge.imagelayers.io/jnbt/postfixadmin:latest.svg)](https://imagelayers.io/?images=jnbt/postfixadmin:latest)

## Docker run

    docker run --rm -it \
      --network backend \
      --name postfixadmin \
      -P \
      jnbt/postfixadmin

### Setup database

In case you want to automatically create the MySQL database layout run the container with `app:init`:

    docker run --rm -it \
      --network backend \
      -e ADMIN_USERNAME=root@example.org \
      -e ADMIN_PASSWORD=s3cr3t \
      -e SETUP_PASSWORD=0th3rs3cr3t \
      jnbt/postfixadmin \
      app:init

**Warning:** Postfixadmin uses SQL statements which won't work when running your
database in strict mode. This docker container tries to patch the initial SQL
import, but you might need to run the `app:init` more then once!

## Configuration

### MySQL

The default configuration for MySQL is:

```
-e MYSQL_HOST=mysql
-e MYSQL_USER=postfix
-e MYSQL_DATABASE=postfix
-e MYSQL_PASSWORD=postfix
```

### Postfixadmin via environment variables

You can configure all simple [PFA configuration options](https://sourceforge.net/p/postfixadmin/code/HEAD/tree/trunk/config.inc.php)
using enviroment variables **prefixed** with `PA_`.

**Example:** Using quotas for mail accounts

```
-e PA_QUOTA=YES
-e PA_USED_QUOTAS=YES
```

### Postfixadmin via php files

In case you need a more complex configuration, you can mount a directory holding
further php-based configuration files:

```
-v /path/to/config/folder:/config/custom:ro
```

Where a custom config file could be `/path/to/config/folder/user.inc.php`:

```
<?php

$CONF['default_aliases'] = array (
    'abuse' => 'admin',
    'hostmaster' => 'admin',
    'postmaster' => 'admin',
    'webmaster' => 'admin'
);
```

## Software

* [alpine:3.4](https://hub.docker.com/_/alpine)
* [Postfixadmin 2.9.3](http://postfixadmin.sourceforge.net)

## Release

* `Makefile`: Bump `VERSION`
* `Dockerfile`: Bump `POSTFIXADMIN_VERSION` and `RELEASE_DATE`
* `README.md`: Bump versions in `Software` section
* Run `make release`
