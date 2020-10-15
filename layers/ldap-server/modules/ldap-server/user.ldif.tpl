dn: uid=${username},ou=${ou},${basedn}
cn: ${name}
sn: ${name}
givenname: ${name}
objectclass: top
objectclass: person
objectclass: organizationalPerson
objectclass: inetOrgPerson
objectClass: pcfExtendedPerson
ou: Software Development
ou: ${ou}
l: DC Metro Area
uid: ${username}
telephonenumber: +1 703 111 1111
facsimiletelephonenumber: +1 703 111 1110
roomnumber: A17
userPassword: unused
userCertificate;binary:< file:///tmp/conf/users/${username}.der
${roles}