include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

#all
acl "clients" {
	127.0.0.0/8;
	${client_cidr};
};

options {
	#listen-on port 53 { 127.0.0.1; 10.3.0.27; }; ## SLAVE
	listen-on-v6 { none; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";

	tcp-clients 50;

	# Disable built-in server information zones
	version none;
	hostname none;
	server-id none;

	recursion yes;
	recursive-clients 50;
	allow-recursion { clients; };
	allow-query { clients; };
	allow-transfer { none; };

	auth-nxdomain no;
	notify no;
	dnssec-enable yes;
	dnssec-validation auto;
	dnssec-lookaside auto;

	bindkeys-file "/etc/named.iscdlv.key";
	managed-keys-directory "/var/named/dynamic";
	pid-file "/var/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

# Specifications of what to log, and where the log messages are sent
logging {
	channel "common_log" {
		file "/var/log/named/named.log" versions 10 size 5m;
		severity dynamic;
		print-category yes;
		print-severity yes;
		print-time yes;
	};
	category default { "common_log"; };
	category general { "common_log"; };
	category queries { "common_log"; };
	category client { "common_log"; };
	category security { "common_log"; };
	category query-errors { "common_log"; };
	category lame-servers { null; };
};

zone "." IN {
	type hint;
	file "named.ca";
};

# Internal zone definitions
zone "${zone_name}" {
	type slave;
	file "data/db.${zone_name}";
	masters { ${master_ip}; };
	allow-notify { ${master_ip}; };
};

zone "${reverse_cidr_prefix}.in-addr.arpa" {
	type slave;
	file "data/db.${reverse_cidr_prefix}";
	masters { ${master_ip}; };
	allow-notify { ${master_ip}; };
};