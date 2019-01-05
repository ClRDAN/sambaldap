#! /bin/bash
# Aitor Galilea@edt ASIX M06 2018-2019
# instalacion cliente SAMBA-PAM

#  - copiamos archivos de configuracion
# ---------------------------------------
cp /opt/docker/nsswitch.conf /etc/nsswitch.conf
cp /opt/docker/system-auth-edt /etc/pam.d/system-auth-edt
cp /opt/docker/pam_mount.conf.xml /etc/security/pam_mount.conf.xml
ln -sf /etc/pam.d/system-auth-edt /etc/pam.d/system-auth
./authconfig.conf

# - cramos usuarios locales
#---------------------------
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

# - arrancamos servicios
#------------------------
/usr/sbin/nslcd && echo "nslcd Ok"
/usr/sbin/nscd && echo "nscd Ok"
