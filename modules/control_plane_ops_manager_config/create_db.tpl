#!/usr/bin/env bash

export PGPASSWORD=${postgres_password}

psql="psql -h ${postgres_host} -p ${postgres_port} -U ${postgres_username} ${postgres_db_name}"
if ! $psql -c "SELECT 1;" >/dev/null 2>&1; then
    createdb -h ${postgres_host} -p ${postgres_port} -U ${postgres_username} ${postgres_db_name}
    echo "Created database ${postgres_db_name}."
else
    echo "Database ${postgres_db_name} already exists."
fi

export PGPASSWORD=${postgres_uaa_password}

psql="psql -h ${postgres_host} -p ${postgres_port} -U ${postgres_uaa_username} ${postgres_uaa_db_name}"
if ! $psql -c "SELECT 1;" >/dev/null 2>&1; then
    createdb -h ${postgres_host} -p ${postgres_port} -U ${postgres_uaa_username} ${postgres_uaa_db_name}
    echo "Created database ${postgres_uaa_db_name}."
else
    echo "Database ${postgres_uaa_db_name} already exists."
fi

mysql -h ${mysql_host} -P ${mysql_port} -u ${mysql_username} --password=${mysql_password} <<SQL
create database if not exists ${mysql_db_name};
SQL
