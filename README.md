# SAMBA con LDAP como backend

## @edt ASIX M06 2018-2019

En este repositorio se encuentran los archivos necesarios para montar un sistema de servidores LDAP y SAMBA (con LDAP 
haciendo de backend de SAMBA). Por lo tanto el sistema a montar consta de dos
contenedores docker: 
* Servidor LDAP. Utilizamos el mismo que para prácticas anteriores. Sus archivos de configuración están dentro del
directorio ldapserver, en el repositorio https://github.com/ClRDAN/sambaldap  
La imágen del docker está en https://hub.docker.com/r/agalilea/ldapsmb y se puede descargar con  
``` docker pull agalilea/ldapsmb```  
* Servidor SAMBA. Sus archivos de configuración están dentro del directorio smbserver, en el repositorio 
https://github.com/ClRDAN/sambaldap  
La imágen del docker está en https://hub.docker.com/r/agalilea/samba y se puede descargar con  
```docker pull agalilea/samba```  
El contenido de cada directorio está detallado en los archivos README incluidos en los mismos directorios. 

### Arquitectura
Para que SAMBA utilice LDAP como backend y los directorios HOME se automonten mediante SAMBA al loguear necesitamos:
* **Red local** en la que situar los equipos denominada **sambanet**. Se crea usando el comando  
```docker network create sambanet ```  
* **Servidor LDAP**. container denominado **ldap** generado a partir de la imagen ldapsmb. Se arranca mediante el comando  
```docker run --rm --name ldap --hostname ldap --network sambanet -d agalilea/ldapsmb ```  
* **Servidor SAMBA**. container denominado **samba** generado a partir de la imagen samba. Se arranca mediante el comando  
```docker run --rm --name samba --hostname samba --network sambanet -d agalilea/samba ```  

### Configuración
En el servidor LDAP tan sólo hay que añadir un schema específico para SAMBA en /etc/openldap/schema, que es el que nos 
permitirá almacenar los datos de SAMBA en la base de datos LDAP.  
En el servidor SAMBA hay que:
* Instalar los paquetes samba y samba-client para SAMBA, y smbldap-tools para configurar LDAP para que utilice LDAP 
como backend.
* Configurar la conexión con LDAP usando las herramientas authconfig y nsswitch
* Arrancar los servicios para LDAP (nscd y nslcd) y para SAMBA (smbd y nmbd)
* Configurar los shares (creamos directorios y archivos compartidos, modificamos /etc/samba/smb.conf, establecemos las 
configuraciones para compartirlos) y la integración SAMBA-LDAP
  * En /etc/samba/smb.conf definimos el backend LDAP incluyendo  
  ```passdb backend = ldapsam:ldap://172.19.0.3``` 
  y una serie de líneas con los sufijos que se usarán en LDAP para 
  guardar los nuevos usuarios, grupos, hosts y otras configuraciones necesarias.
  * En /etc/smbldap-tools/smbldap.conf especificamos dónde se encuentra el servidor LDAP master y slave (en nuestro 
  caso ambos son el mismo), establecemos el sufijo LDAP como 'dc=edt,dc=org' y los sufijos de los distintos tipos de 
  elemento ('ou=usuaris,dc=edt,dc=org' 'ou=grups,dc=edt,dc=org'...)  
* Guardar la contraseña del administrador (root) de SAMBA y LDAP con la herramienta smbpasswd (secret), de modo que 
SAMBA pueda usarla
* Crear en LDAP las estructuras de datos necesarias para almacenar la información de SAMBA mediante la utilidad 
smbldap-populate. Esta herramienta también pide que introduzcamos la clave del usuario root del dominio (edt.org, 
almacenado en LDAP-> secret)

* Crear los usuarios locales y de SAMBA mediante la herramienta smbpasswd


/etc/samba/smb.conf
```
[global]
        workgroup = MYGROUP
        server string = Samba Server Version %v
        log file = /var/log/samba/log.%m
        max log size = 50
        security = user
        passdb backend = ldapsam:ldap://172.21.0.2
          ldap suffix = dc=edt,dc=org
          ldap user suffix = ou=usuaris
          ldap group suffix = ou=grups
          ldap machine suffix = ou=hosts
          ldap idmap suffix = ou=domains
          ldap admin dn = cn=Manager,dc=edt,dc=org
          ldap ssl = no
          ldap passwd sync = yes
        load printers = yes
        cups options = raw
[homes]
        comment = Home Directories
        browseable = no
        writable = yes
;       valid users = %S
;       valid users = MYDOMAIN\%S
```

/etc/smbldap-tools/smbldap_bind.conf
```
# $Id$
#
############################
# Credential Configuration #
############################
# Notes: you can specify two differents configuration if you use a
# master ldap for writing access and a slave ldap server for reading access
# By default, we will use the same DN (so it will work for standard Samba
# release)
slaveDN="cn=Manager,dc=edt,dc=org"
slavePw="secret"
masterDN="cn=Manager,dc=edt,dc=org"
masterPw="secret"
```

/etc/smbldap-tools/smbldap.conf
```
# $Id$
#
# smbldap-tools.conf : Q & D configuration file for smbldap-tools

#  This code was developped by IDEALX (http://IDEALX.org/) and
#  contributors (their names can be found in the CONTRIBUTORS file).
#
#                 Copyright (C) 2001-2002 IDEALX
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
#  USA.

#  Purpose :
#       . be the configuration file for all smbldap-tools scripts

##############################################################################
#
# General Configuration
#
##############################################################################

# Put your own SID. To obtain this number do: "net getlocalsid".
# If not defined, parameter is taking from "net getlocalsid" return
#SID="S-1-5-21-2252255531-4061614174-2474224977"

# Domain name the Samba server is in charged.
# If not defined, parameter is taking from smb.conf configuration file
# Ex: sambaDomain="IDEALX-NT"
#sambaDomain="DOMSMB"

##############################################################################
#
# LDAP Configuration
#
##############################################################################

# Notes: to use to dual ldap servers backend for Samba, you must patch
# Samba with the dual-head patch from IDEALX. If not using this patch
# just use the same server for slaveLDAP and masterLDAP.
# Those two servers declarations can also be used when you have
# . one master LDAP server where all writing operations must be done
# . one slave LDAP server where all reading operations must be done
#   (typically a replication directory)

# Slave LDAP server URI
# Ex: slaveLDAP=ldap://slave.ldap.example.com/
# If not defined, parameter is set to "ldap://127.0.0.1/"
slaveLDAP="ldap://172.21.0.2/"

# Master LDAP server URI: needed for write operations
# Ex: masterLDAP=ldap://master.ldap.example.com/
# If not defined, parameter is set to "ldap://127.0.0.1/"
masterLDAP="ldap://172.21.0.2/"

# Use TLS for LDAP
# If set to 1, this option will use start_tls for connection
# (you must also used the LDAP URI "ldap://...", not "ldaps://...")
# If not defined, parameter is set to "0"
ldapTLS="0"

# How to verify the server's certificate (none, optional or require)
# see "man Net::LDAP" in start_tls section for more details
verify="require"

# CA certificate
# see "man Net::LDAP" in start_tls section for more details
cafile="/etc/pki/tls/certs/ldapserverca.pem"

# certificate to use to connect to the ldap server
# see "man Net::LDAP" in start_tls section for more details
clientcert="/etc/pki/tls/certs/ldapclient.pem"

# key certificate to use to connect to the ldap server
# see "man Net::LDAP" in start_tls section for more details
clientkey="/etc/pki/tls/certs/ldapclientkey.pem"

# LDAP Suffix
# Ex: suffix=dc=IDEALX,dc=ORG
suffix="dc=edt,dc=org"

# Where are stored Users
# Ex: usersdn="ou=Users,dc=IDEALX,dc=ORG"
# Warning: if 'suffix' is not set here, you must set the full dn for usersdn
usersdn="ou=usuaris,${suffix}"

# Where are stored Computers
# Ex: computersdn="ou=Computers,dc=IDEALX,dc=ORG"
# Warning: if 'suffix' is not set here, you must set the full dn for computersdn
computersdn="ou=hosts,${suffix}"

# Where are stored Groups
# Ex: groupsdn="ou=Groups,dc=IDEALX,dc=ORG"
# Warning: if 'suffix' is not set here, you must set the full dn for groupsdn
groupsdn="ou=grups,${suffix}"

# Where are stored Idmap entries (used if samba is a domain member server)
# Ex: idmapdn="ou=Idmap,dc=IDEALX,dc=ORG"
# Warning: if 'suffix' is not set here, you must set the full dn for idmapdn
idmapdn="ou=domains,${suffix}"

# Where to store next uidNumber and gidNumber available for new users and groups
# If not defined, entries are stored in sambaDomainName object.
# Ex: sambaUnixIdPooldn="sambaDomainName=${sambaDomain},${suffix}"
# Ex: sambaUnixIdPooldn="cn=NextFreeUnixId,${suffix}"
sambaUnixIdPooldn="sambaDomainName=${sambaDomain},${suffix}"

# Default scope Used
scope="sub"

# Unix password hash scheme (CRYPT, MD5, SMD5, SSHA, SHA, CLEARTEXT)
# If set to "exop", use LDAPv3 Password Modify (RFC 3062) extended operation.
password_hash="SSHA"
```

### Bibliografía
https://help.ubuntu.com/lts/serverguide/samba-ldap.html.en
https://github.com/edtasixm06/samba/blob/master/samba:18ldapsam/README.md

