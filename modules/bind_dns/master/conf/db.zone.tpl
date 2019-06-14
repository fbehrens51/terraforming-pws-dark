$TTL 86400	; 1 day
@			IN SOA	dns1.${zone_name}. root.${zone_name}. (
				2018010700 ; Serial
				3600       ; Refresh (1 hour)
				3600       ; Retry (1 hour)
				604800     ; Expire (1 week)
				3600       ; Minimum (1 hour)
)
@		NS	dns1.${zone_name}.
@		NS	dns2.${zone_name}.
@		NS	dns3.${zone_name}.
@		A	${master_ip}
@		A	${slave_ip_1}
@		A	${slave_ip_2}
dns1		A	${master_ip}
dns2		A	${slave_ip_1}
dns3		A	${slave_ip_2}
