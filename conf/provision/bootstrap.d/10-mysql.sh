#!/usr/bin/env bash

IMAGE_FAMILY=$(docker-image-info family)


mkdir -p /etc/mysql/
ln -sf /opt/docker/etc/my.cnf /etc/my.cnf

mkdir -p /run/mysqld
mkdir -p /docker-entrypoint-initdb.d
