#!/usr/bin/env bash

function create_postgres_db() {
    username=$1
    password=$2
    db_name=$3

    export PGPASSWORD=$${password}

    psql="psql -h ${postgres_host} -p ${postgres_port} -U $${username} $${db_name}"
    if ! $psql -c "SELECT 1;" >/dev/null 2>&1; then
        createdb -h ${postgres_host} -p ${postgres_port} -U $${username} $${db_name}
        echo "Created database $${db_name}."
    else
        echo "Database $${db_name} already exists."
    fi
}

create_postgres_db ${postgres_username} ${postgres_password} ${postgres_db_name}
create_postgres_db ${postgres_uaa_username} ${postgres_uaa_password} ${postgres_uaa_db_name}

mysql -h ${mysql_host} -P ${mysql_port} -u ${mysql_username} --password=${mysql_password} <<SQL
create database if not exists ${mysql_db_name};
SQL
