if [ -d /db/mysql ]; then
  echo "[i] MySQL directory already present, skipping creation"
else
  echo "[i] MySQL data directory not found, creating initial DBs"

  MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-"$(pwgen 12 1)"}
  
  echo "[i] MySQL root Password: $MYSQL_ROOT_PASSWORD"

  mysql_install_db --user=root > /dev/null

  MYSQL_DATABASE=${MYSQL_DATABASE:-""}
  MYSQL_USER=${MYSQL_USER:-""}
  MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

  tfile=`mktemp`
  if [ ! -f "$tfile" ]; then
      return 1
  fi

  cat << EOF > $tfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
SET PASSWORD FOR 'root'@localhost = PASSWORD("");
EOF

  if [ "$MYSQL_DATABASE" != "" ]; then
    echo "[i] Creating database: $MYSQL_DATABASE"
    echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" >> $tfile

    if [ "$MYSQL_USER" != "" ]; then
      echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
      echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
      echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
    fi
  fi

  /usr/bin/mysqld --user=root --bootstrap --verbose=0 < $tfile
  rm -f $tfile

  echo "[docker-entrypoint-initdb.d] finding files"
  if [ "$(ls -A /docker-entrypoint-initdb.d)" ]; then
    echo "[docker-entrypoint-initdb.d] found init files"
    SOCKET="/tmp/mysql.sock"
    mysqld --user=root --skip-networking --socket="${SOCKET}" &

    for i in {30..0}; do
      if mysqladmin --socket="${SOCKET}" ping &>/dev/null; then
        break
      fi
      echo '[docker-entrypoint-initdb.d] Waiting for server...'
      sleep 1
    done
    if [ "$i" = 0 ]; then
      echo >&2 '[docker-entrypoint-initdb.d] Timeout during MySQL init.'
      exit 1
    fi

    for f in /docker-entrypoint-initdb.d/*; do
      case "$f" in
        *.sh)  echo "[docker-entrypoint-initdb.d] running $f"; . "$f" ;;
        *.sql) echo "[docker-entrypoint-initdb.d] running $f"; mysql --socket="${SOCKET}" -hlocalhost "${MYSQL_DATABASE}" < "$f";;
        *)     echo "[docker-entrypoint-initdb.d] ignoring $f" ;;
      esac
    done
    echo '[docker-entrypoint-initdb.d] Finished.'
    mysqladmin shutdown --user=root --socket="${SOCKET}"
  fi
fi
