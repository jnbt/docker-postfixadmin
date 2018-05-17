#!/usr/bin/env bash
set -e

[[ $DEBUG == true ]] && set -x

cmd_php="php -S 0.0.0.0:80 -c /php.ini -t /www/public"

export MYSQL_HOST
export MYSQL_USER
export MYSQL_PASSWORD
export MYSQL_DATABASE

MYSQL_HOST=${MYSQL_HOST:-mysql}
MYSQL_USER=${MYSQL_USER:-postfix}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-postfix}
MYSQL_DATABASE=${MYSQL_DATABASE:-postfix}

wait_for_mysql() {
  : "${MYSQL_HOST?Need to set MYSQL_HOST}"
  : "${MYSQL_USER?Need to set MYSQL_USER}"
  : "${MYSQL_PASSWORD?Need to set MYSQL_PASSWORD}"
  : "${MYSQL_DATABASE?Need to set MYSQL_DATABASE}"

  until mysql --host=$MYSQL_HOST --user=$MYSQL_USER --password=$MYSQL_PASSWORD --execute="USE $MYSQL_DATABASE;" &>/dev/null; do
    echo "[INFO] Waiting for MySQL connectivity"
    sleep 2
  done
}

wait_for_php() {
  until curl --output /dev/null --silent --get --fail "http://localhost"; do
    echo "[INFO] Waiting for PHP server"
    sleep 2
  done
}

init_config() {
  mkdir -p /config
  echo "<?php">/config/__config.php
  for e in $(env); do
    case $e in
      PA_*)
        e1=$(expr "$e" : 'PA_\([A-Z_]*\)')
        e2=$(expr "$e" : '\([A-Z_]*\)')
        echo "\$CONF['${e1,,}'] = getenv('$e2');">>/config/__config.php
    esac
  done
  echo "?>">>/config/__config.php
}

patch_upgrade() {
  # The postfixadmin SQL statements use invalid default values for dates
  # which are not allowed in SQL strict mode
  sed -i 's/0000-00-00/2001-01-01/g' /www/public/upgrade.php
}

init_or_upgrade_db() {
  SETUP_PASSWORD="${SETUP_PASSWORD:-s3cr3t}"

  salt=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 32 | head -n 1)
  password_hash=$(echo -n "$salt:$SETUP_PASSWORD" | sha1sum | cut -d ' ' -f 1)
  setup_password_hash="$salt:$password_hash"
  echo "<?php \$CONF['setup_password'] = '$setup_password_hash'; ?>">/config/___setup_password.php

  $cmd_php &
  wait_for_php
  pid_php=$!

  if [ $1 = "init" ]; then
    : "${ADMIN_USERNAME?Need to set ADMIN_USERNAME}"
    : "${ADMIN_PASSWORD?Need to set ADMIN_PASSWORD}"
    echo "[INFO] Creating database"
    curl --silent --output /dev/null http://localhost/setup.php
    echo "[INFO] Creating admin user"
    curl --silent --output /dev/null --data "form=createadmin&setup_password=$SETUP_PASSWORD&username=$ADMIN_USERNAME&password=$ADMIN_PASSWORD&password2=$ADMIN_PASSWORD" http://localhost/setup.php
  else
    echo "[INFO] Updating database (if needed)"
    curl --silent --output /dev/null http://localhost/setup.php
  fi

  kill $pid_php
  wait $pid_php 2>/dev/null || true
  rm -rf /www/public/setup.php /config/___setup_password.php
}

start_server() {
  echo "[INFO] Starting server"
  rm -rf /www/public/setup.php /config/___setup_password.php
  exec $cmd_php
}

case ${1} in
  app:help)
    echo "Available options:"
    echo " app:start        - Starts the postfix server (default)"
    echo " app:init         - Initialize the database, but don't start it."
    echo " app:help         - Displays this help"
    echo " [command]        - Execute the specified command, eg. bash."
    ;;
  app:init|app:start)
    wait_for_mysql
    patch_upgrade
    init_config

    case ${1} in
      app:start)
        init_or_upgrade_db "upgrade"
        start_server
        ;;
      app:init)
        init_or_upgrade_db "init"
        ;;
    esac
    ;;
  *)
    exec "$@"
    ;;
esac
