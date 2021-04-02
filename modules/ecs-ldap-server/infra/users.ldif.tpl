dn: uid=${user.common_name},ou=${user.ou},dc=pcfeagle,dc=cf-app,dc=com
cn: ${user.common_name}
sn: ${user.common_name}
objectclass: top
objectclass: person
objectclass: organizationalPerson
objectclass: inetOrgPerson
objectClass: pcfExtendedPerson
ou: ${user.ou}
userCertificate;binary:: ${join("\n ", split("\n", trimspace(der)))}
%{ for role in user.roles ~}
role: ${role}
%{ endfor }
