#! /bin/bash
# Aitor Galilea@edt ASIX M06 2018-2019
# instalación servidor Samba con backend LDAP
# -------------------------------------
#
# - CREAMOS USUARIOS LOCALES
#----------------------------
groupadd localgrp01
groupadd localgrp02
useradd -g users -G localgrp01 local01
useradd -g users -G localgrp01 local02
useradd -g users -G localgrp02 local03
useradd -g users -G localgrp02 local04
echo "local01" | passwd --stdin local01
echo "local02" | passwd --stdin local02
echo "local03" | passwd --stdin local03
echo "local04" | passwd --stdin local04
./authconfig.conf
cp /opt/docker/nsswitch.conf /etc/nsswitch.conf
cp /opt/docker/smb.conf /etc/samba/smb.conf

# - ARRANCAMOS SERVICIOS LDAP
#------------------------
/usr/sbin/nslcd && echo "nslcd OK"
/usr/sbin/nscd && echo "nscd OK"


# - CREAMOS DIRECTORIOS COMPARTIDOS 
# ----------------------------------
mkdir /tmp/home
mkdir /tmp/home/pere
mkdir /tmp/home/pau
mkdir /tmp/home/anna
mkdir /tmp/home/marta
mkdir /tmp/home/jordi
mkdir /tmp/home/admin
mkdir /tmp/home/public

cp README.md /tmp/home/pere/README.pere
cp README.md /tmp/home/pau/README.pau
cp README.md /tmp/home/anna/README.anna
cp README.md /tmp/home/marta/README.marta
cp README.md /tmp/home/jordi/README.jordi
cp README.md /tmp/home/admin/README.admin
cp README.md /tmp/home/public/README.public

chown -R pere.users /tmp/home/pere
chown -R pau.users /tmp/home/pau
chown -R anna.alumnes /tmp/home/anna
chown -R marta.alumnes /tmp/home/marta
chown -R jordi.users /tmp/home/jordi
chown -R admin.wheel /tmp/home/admin
chown -R nobody.nobody /tmp/home/public
chmod -R 777 tmp/home/public

# - CONFIGURAMOS LDAP COMO BACKEND
# -----------------------------------------------------------
cp /opt/docker/smbldap.conf /etc/smbldap-tools/smbldap.conf
cp /opt/docker/smbldap_bind.conf /etc/smbldap-tools/smbldap_bind.conf
smbpasswd -w secret
echo -e "secret\nsecret" | smbldap-populate -i /opt/docker/populate.ldif

# - CREAMOS USUARIOS SAMBA
#--------------------------
echo -e "pere\npere" | smbpasswd -a pere
echo -e "pau\npau" | smbpasswd -a pau
echo -e "anna\nanna" | smbpasswd -a anna
echo -e "marta\nmarta" | smbpasswd -a marta
echo -e "jordi\njordi" | smbpasswd -a jordi
echo -e "admin\nadmin" | smbpasswd -a admin
echo -e "local01\nlocal01" | smbpasswd -a local01

# - ARRANCAMOS SERVICIOS SAMBA
#------------------------------
/usr/sbin/nmbd && echo "nmb OK"
/usr/sbin/smbd && echo "smb OK"
