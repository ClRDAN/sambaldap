# SAMBA ldapsam

## @edt ASIX M06 2018-2019

Podeu trobar les imatges docker al Dockehub de [edtasixm06](https://hub.docker.com/u/edtasixm06/)

Podeu trobar la documentació del mòdul a [ASIX-M06](https://sites.google.com/site/asixm06edt/)


ASIX M06-ASO Escola del treball de barcelona

### Imatges:

* **edtasixm06/samba:18ldapsam** Servidor SAMBA amb backend LDAP *ldapsam*. Requereix de l'ús de un 
servidor ldap preparat amb l'schema samba. Les dades dels usuaris samba es desen en els comptes
 d'usuari ldap.

### Arquitectura

Per implementar un host amb usuaris unix i ldap on els homes dels usuaris es muntin via samba de un 
servidor de disc extern cal:

  * **sambanet** Una xarxa propia per als containers implicats.

  * **edtasixm06/ldapserver:18samba** Un servidor ldap en funcionament amb els usuaris de xarxa.

  * **edtasixm06/samba:18ldapsam** Un servidor samba que utilitza *ldapsam* com a backend.
Exporta els homes dels usuaris com a shares via *[homes]*. Aquest servidor està configurat per tenir
usuaris locals i usuaris LDAP. Està configurat correctament l'accés al servidor LDAP.
Contindrà:

    * *Usuaris unix* Samba requereix la existència de usuaris unix. Per tant caldrà disposar dels usuaris unix,
poden ser locals o de xarxa via LDAP. Així doncs, el servidor samba ha d'estar configurat amb nscd i nslcd per
poder accedir al ldap. Amb getent s'han de poder llistar tots els usuaris i grups de xarxa.

    * *homes* Cal que els usuaris tinguin un directori home. Els usuaris unix local ja en tenen en crear-se
l'usuari, però els usuaris LDAP no. Per tant cal crear el directori home dels usuaris ldap i assignar-li la 
propietat i el grup de l'usuari apropiat.

    * *Usuaris samba* Cal crear els comptes d'usuari samba (recolsats en l'existència del mateix usuari unix/ldap).
Per a cada usuari samba els pot crear amb *smbpasswd* el compte d'usuasi samba assignant-li el password de samba. 
Aquest es desarà en la base de dades ldap. 
Convé que sigui el mateix que el de ldap per tal de que en fer login amb un sol password es validi l'usuari (auth de
pam_ldap.so) i es munti el  home via samba (pam_mount.so).
Samba pot desar els seus usuaris en una base de dades local anomenada **tdbsam** o els pot desar en un servidor ldap 
usant com a backend **ldapsam**. 

  * **hostpam** Un hostpam configurat per accedir als usuarislocals i ldap i que usant pam_mount.so
munta dins del home dels usuaris un home de xarxa via samba. Cal configurar */etc/security/pam_mount.conf.xml* 
per muntar el recurs samba dels *[homes]*.

## Configuració SAMBA ldapsam

Per tal de que el servei SAMBA utilitzi com a backend LDAp caldrà fer una sèrie de passos que s'expliquen detalladament 
en aquest apartat. Un resum dels passos és:

 * Assegurar-se que el servidor ldap inclou l'schema samba.
 * Incorporar el paquet smbldap-tools al servidor samba.
 * Configurar correctament el servidor samba establint el backend *ldapsam* i les seves opcions.
 * Configurar els fitxers de smbldap-tools que permeten inicialitzar la base de dades ldap com a backend de samba. Aquests fitxers són:
   * /etc/smbldap-tools/smbldap.conf Configura les opcions de samba en el ldap.
   * /etc/smbldap-tools/smbldap_bind.conf Indica com s'ha de fer el bind de samba amb ldap, el rootDN i password per contactar i administrar ldap.
 * Generar el password d'administrador de samba/ldap amb *smbpasswd -x passwd*. Aquest es desa localment al fitxer *secrets.db*.
 * [ test ] podem fer un test de que tot funciona bé amb les ordres *net getlocalsid* i *net getdomainsid*.
 * Fer el populate de samba a la base de dades ldap. És a dir, per desar la informació de SAMBA a ldap 
cal crear les entitats apropiades per emmagatzemar-ho tot. Això es fa amb la utilitat **smbldap-populate**.
Sol·licita establir el password amb el que samba contactarà amb ldap.
 * [test] podem verificar que s'ha fet el populate llistant el DIT de ldap amb *ldapsearch -x -LLL*.
 * [test] amb l'ordre *pdbedit -L* podem observar els usuaris root i nobody afegits.
 * Ara ja podem crear els usuaris samba, usuari per usuari amb l'ordre *smbpasswd -a usuari*.


#### Execució

```
docker network create sambanet
docker run --rm --name ldap -h ldap --net sambanet -d edtasixm06/ldapserver:18samba

docker run --rm --name samba -h samba --net sambanet -it edtasixm06/samba:18ldapsam

docker run --rm --name host -h host --net sambanet -it edtasixm06/hostpam:18homenfs  #canviar per :18homesamba
```

#### Configuració samba

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

#### Configuració en el hostpam

*/etc/security/pam_mount.conf.xml*
```
<volume user="*" fstype="cifs" server="samba" path="%(USER)"  mountpoint="~/%(USER)" />

```

#### Exemple en el hostpam
```
[root@host docker]# su - local01

[local01@host ~]$ su - anna
pam_mount password:

[anna@host ~]$ ll
total 0
drwxr-xr-x+ 2 anna alumnes 0 Dec 14 20:27 anna

[anna@host ~]$ mount -t cifs
//samba2/anna on /tmp/home/anna/anna type cifs (rw,relatime,vers=1.0,cache=strict,username=anna,domain=,uid=5002,forceuid,gid=600,forcegid,addr=172.21.0.2,unix,posixpaths,serverino,mapposix,acl,rsize=1048576,wsize=65536,echo_interval=60,actimeo=1)
```

