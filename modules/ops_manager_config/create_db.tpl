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

create_postgres_db ${postgres_cw_username} ${postgres_cw_password} ${postgres_cw_db_name}

mysql -h ${rds_address} -u ${rds_username} --password=${rds_password} <<SQL
create database if not exists director;
create database if not exists ccdb;
create database if not exists notifications;
create database if not exists autoscale;
create database if not exists app_usage_service;
create database if not exists routing;
create database if not exists diego;
create database if not exists account;
create database if not exists nfsvolume;
create database if not exists networkpolicyserver;
create database if not exists silk;
create database if not exists locket;
create database if not exists uaa;
create database if not exists credhub;
create database if not exists portal;
SQL
