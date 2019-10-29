#!/usr/bin/env bash

export PGPASSWORD=${postgres_password}

dbname="concourse"

psql="psql -h ${postgres_host} -p ${postgres_port} -U ${postgres_username} $dbname"
if ! $psql -c "SELECT 1;" >/dev/null 2>&1; then
    createdb -h ${postgres_host} -p ${postgres_port} -U ${postgres_username} $dbname
    echo "Created database $dbname."
else
    echo "Database $dbname already exists."
fi
