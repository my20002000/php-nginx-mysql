#!/usr/bin/env bash

source /opt/docker/bin/config.sh

exec /usr/bin/mysqld --user=root --console
