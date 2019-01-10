# PAM
## @edt ASIX M06-ASO Curs 2018-2019

Podeu trobar les imatges docker al Dockehub de [edtasixm06](https://hub.docker.com/u/edtasixm06/)

Podeu trobar la documentació del mòdul a [ASIX-M06](https://sites.google.com/site/asixm06edt/)

ASIX M06-ASO Escola del treball de barcelona


* **hostpam:18homesamba** host pam amb authenticació ldap. Munta els homes de l'usuari via samba.
Per posar en funcionament aquest model calen tres elements: un servidor LDAP, un servidor SAMBA i un host que actua de
client amb PAM + LDAP + pam_mount.so per carregar els homes dels usuaris via SAMBA. Cal instal·lar *cifs-utils*.


Fer que els homes dels usuaris es muntin per samba. Primer caldrà en un servidor samba crear els directoris homes dels usuaris, i assignar-los els permisos apropiats, propietari i grup (recursivament). Podem fer que el servidor samba sigui primerament el nostre host amb l’adreça de docker, i posteriorment fabricar un container servidor samba.

Si volem que els homes de xarxa dels usuaris es muntin individualment, per exemple posant un directori home-xarxa dins del home local, cal instal·lar pam_mount i configurar pam_mount.conf.xml. Aquest usarà miunt.cifs per muntar el recurs de samba i per això cal instal·lar *cifs-utils*.
És especialment important configurar correctament els permisos amb què es munta el directori de xarxa, el propietari i grup ha de ser el de l’usuari.


#### Execució

```
docker run --rm --name ldap -h ldap --net sambanet -d edtasixm06/ldapserver:18group
docker run --rm --name host -h host --net sambanet --privileged -it edtasixm06/hostpam:18homesamba

docker run --rm --name samba -h samba --net sambanet --privileged -it edtasixm06/samba:18ldapusers
o bé
docker run --rm --name samba -h samba --net sambanet --privileged -it edtasixm06/samba:18ldapsam

```

#### Configuracions

Cal instal-lar al host client el paquet **cifs-utils** per poder disposar del mount.cifs.

pam_mount.conf.xml (només a pere se li genera el  ramdisk):
```
<volume user="*" fstype="cifs" server="samba" path="%(USER)"  mountpoint="~/%(USER)" />
```


#### Utilització

```
[root@host docker]# su - local01

[local01@host ~]$ su - anna
pam_mount password:
Creating directory '/tmp/home/anna'.

[anna@host ~]$ ll
total 0
drwxr-xr-x+ 2 anna alumnes 0 Dec 15 18:59 anna

[anna@host ~]$ mount -t cifs
//samba/anna on /tmp/home/anna/anna type cifs (rw,relatime,vers=1.0,cache=strict,username=anna,domain=,uid=5002,forceuid,gid=600,forcegid,addr=172.21.0.3,unix,posixpaths,serverino,mapposix,acl,rsize=1048576,wsize=65536,echo_interval=60,actimeo=1)
```

