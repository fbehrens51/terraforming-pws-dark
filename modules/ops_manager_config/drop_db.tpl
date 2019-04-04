#!/usr/bin/env bash

mysql -h ${rds_address} -u ${rds_username} --password=${rds_password} <<SQL
drop database if exists director;
drop database if exists ccdb;
drop database if exists notifications;
drop database if exists autoscale;
drop database if exists app_usage_service;
drop database if exists routing;
drop database if exists diego;
drop database if exists account;
drop database if exists nfsvolume;
drop database if exists networkpolicyserver;
drop database if exists silk;
drop database if exists locket;
drop database if exists uaa;
drop database if exists credhub;
SQL
