#!/usr/bin/env bash
. ~/.sh.d/pg.sh
# psql-local -c "create role sonar with login inherit createdb createrole replication password 'sonar';"
# \l list dbs
# psql-local -c "drop database sonar;"
# psql-local -c "create database sonar with owner = sonar encoding = 'UTF8';"
# psql-sonar -c "update users set reset_password=false where login='admin';"
