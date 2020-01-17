include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

# Disable rndc management
controls { };

# Limit access to local network and homelab LAN
acl "clients" {
	127.0.0.0/8;
	${client_cidr};
};

options {
    #commented out following line to listen on all IPs
	#listen-on port 53 { 127.0.0.1; 10.3.0.4; }; ## MASTER
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

	auth-nxdomain no;
	notify no;
	dnssec-enable no;
	#dnssec-validation auto;
	#dnssec-lookaside auto;

	bindkeys-file "/etc/named.iscdlv.key";
	managed-keys-directory "/var/named/dynamic";
	pid-file "/var/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

# Specifications of what to log, and where the log messages are sent
logging {
    channel default_syslog {
        print-time yes;
        print-category yes;
        print-severity yes;
        syslog daemon;
        severity info;
    };
	category default { "default_syslog";};
	category general { "default_syslog";};
	category queries { "default_syslog";};
	category client { "default_syslog";};
	category security { "default_syslog";};
	category query-errors { "default_syslog";};
	category lame-servers { null; };
};

zone "." IN {
	type hint;
	file "named.ca";
};

# Internal zone definitions
zone "${zone_name}" {
	type master;
	file "data/db.${zone_name}";
};
