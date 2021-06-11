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
        listen-on-v6 { none; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";

        tcp-clients 50;

        # Disable built-in server information zones
        version none;
        hostname none;
        server-id none;

        #recursion no;
        allow-query { clients; };
        allow-recursion { clients; };
        allow-transfer { clients; };
        auth-nxdomain no;
        notify no;
        dnssec-enable no;
        dnssec-validation no;

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


%{for forwarder in forwarders}
zone "${forwarder.domain}." IN {
    type forward;
    forward only;
    forwarders { %{for ip in forwarder.forwarder_ips}${ip};%{endfor}  };
};
%{endfor}
