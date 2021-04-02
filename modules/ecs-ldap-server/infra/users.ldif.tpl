dn: dc=pcfeagle,dc=cf-app,dc=com
objectClass: dcObject
objectClass: organization
dc: pcfeagle
o: Tanzu Web Services

dn: ou=Applications,dc=pcfeagle,dc=cf-app,dc=com
objectClass: organizationalUnit
ou: Applications

dn: ou=People,dc=pcfeagle,dc=cf-app,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Servers,dc=pcfeagle,dc=cf-app,dc=com
objectClass: organizationalUnit
ou: Servers


%{ for _, user in users }
dn: uid=${user.common_name},ou=${user.ou},dc=pcfeagle,dc=cf-app,dc=com
cn: ${user.common_name}
sn: ${user.common_name}
objectclass: top
objectclass: person
objectclass: organizationalPerson
objectclass: inetOrgPerson
objectClass: pcfExtendedPerson
ou: ${user.ou}
userCertificate;binary:: ${join("\n ", split("\n", trimspace(user.der)))}
%{ for role in user.roles ~}
role: ${role}
%{ endfor }
%{ endfor }