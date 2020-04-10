$TTL 86400	; 1 day
@			IN SOA	dns1.${zone_name}. root.${zone_name}. (
				2018010700 ; Serial
				3600       ; Refresh (1 hour)
				3600       ; Retry (1 hour)
				604800     ; Expire (1 week)
				3600       ; Minimum (1 hour)
)
%{for index in range(length(master_ips))}
@	           	    NS	dns${index + 1}.${zone_name}.
@		              A 	${master_ips[index]}
dns${index + 1}		A 	${master_ips[index]}
%{endfor}

$TTL 300        ; 5 minutes
${om_subdomain}             A       ${om_public_ip}
*.${system_subdomain}       CNAME   ${pas_elb_dns}.
*.${apps_subdomain}         CNAME   ${pas_elb_dns}.

${control_plane_om_subdomain}    A       ${control_plane_om_public_ip}
${control_plane_plane_subdomain} CNAME   ${control_plane_plane_elb_dns}.

${smtp_subdomain}           A       ${postfix_private_ip}

${splunk_subdomain}         CNAME   ${splunk_search_head_elb_dns}.
${splunk_logs_subdomain}    A       ${splunk_logs_private_ip}
${splunk_monitor_subdomain} CNAME   ${splunk_monitor_elb_dns}.

${grafana_subdomain} CNAME   ${grafana_elb_dns}.
