# php-nginx-mysql
webdevops/php-nginx-mysql

```
services:
  app:
    image: a1
    ports:
      - "8080:80"
    volumes:
      - ./app:/app
      - ./vhost.common.conf:/opt/docker/etc/nginx/vhost.common.d/10-location-root.conf
      - ./a.sql:/docker-entrypoint-initdb.d/a.sql
    environment:
      WEB_DOCUMENT_ROOT: /app/public
      PHP_DISPLAY_ERRORS: 1
      PHP_POST_MAX_SIZE: 100M
      PHP_UPLOAD_MAX_FILESIZE: 100M
      WEB_DOCUMENT_INDEX: index.php
      MYSQL_DATABASE: database1
      MYSQL_USER: user
      MYSQL_PASSWORD: pass

```
```
FROM php-nginx-mysql:7.4-alpine

COPY app/ /app/
COPY vhost.common.conf /opt/docker/etc/nginx/vhost.common.d/10-location-root.conf
COPY a.sql /docker-entrypoint-initdb.d/a.sql
ENV WEB_DOCUMENT_ROOT=/app/public
ENV PHP_DISPLAY_ERRORS=1
ENV PHP_POST_MAX_SIZE=100M
ENV PHP_UPLOAD_MAX_FILESIZE=100M
ENV WEB_DOCUMENT_INDEX=index.php
ENV MYSQL_DATABASE=database1
ENV MYSQL_USER=user
ENV MYSQL_PASSWORD=pass
RUN chmod 777 -R /app

```
```
location / {
    if (!-e $request_filename) {
        rewrite ^(.*)$ /index.php?s=$1 last;
        break;
    }
}

```
