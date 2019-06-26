#!/usr/bin/env bash

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
