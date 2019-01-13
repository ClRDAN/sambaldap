#LDAPSMB
Archivos necesarios para generar una imagen docker con la que montar containers de 
Fedora 27 con un servidor LDAP configurado para actuar como backend de un servidor SAMBA.

La imagen ya creada se encuentra en https://hub.docker.com/r/agalilea/ldapsmb  
```docker pull agalilea/ldapsmb```  
La imagen del servidor SAMBA se encuentra en https://hub.docker.com/r/agalilea/samba
```docker pull agalilea/samba```
La imagen ya creada del host se encuentra en https://hub.docker.com/r/agalilea/  
```docker pull agalilea/hostsambapam```  

El repositorio contiene los siguientes archivos:
* DB_CONFIG: archivo de configuración para bases de datos tipo bdb/hdb. Sustituye al predeterminado al iniciarse el 
container.
* Dockerfile: archivo de creación de la imagen Docker. Este archivo hace que se instalen en el container los paquetes 
  necesarios para LDAP (openldap-clients y openldap-servers) 
* edt.ldif: archivo con los datos de edt.org a introducir en la base de datos LDAP, en formato ldif. Se carga 
automáticamente al iniciar el container.
* install.sh: script que se ejecuta al arrancar la imagen, configura el container (sustituye las configuraciones por 
defecto por las versiones modificadas, carga los datos en la base de datos).
* ldap.conf: archivo de configuración de LDAP. En él tenemos que especificar el dn de la base de datos (dc=edt,dc=org) 
y la URI donde encontrarla (ldap://ldap)  
* samba.schema: archivo de schema de LDAP con las definiciones necesarias para almacenar la información de SAMBA en la 
base de datos LDAP. Al arrancar el container se copia en /etc/openldap/schema.
* slapd.conf: archivo de configuración del daemon slapd. Debemos asegurarnos de que contiene un include con el archivo
de definiciones samba.schema, y de que el sufijo y el rootdn de la base de datos ldap sean los nuestros (dc=edt,dc=org 
y 'cn=Manager,dc=edt,dc=org' respectivamente).
* startup.sh: script que se ejecuta al encender el container. LLama al script install.sh y arranca el daemon slapd. 
