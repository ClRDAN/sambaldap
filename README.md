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

### Arquitectura
Para que SAMBA utilice LDAP como backend y los directorios HOME se automonten mediante SAMBA al loguear necesitamos:
* **Red local** en la que situar los equipos denominada **sambanet**. Se crea usando el comando  
```docker network create sambanet ```  
* **Servidor LDAP**. container denominado **ldap** generado a partir de la imagen ldapsmb. Se arranca mediante el comando  
```docker run --rm --name ldap --hostname ldap --network sambanet -d agalilea/ldapsmb ```  
* **Servidor SAMBA**. container denominado **samba** generado a partir de la imagen samba. Se arranca mediante el comando  
```docker run --rm --name samba --hostname samba --network sambanet -d agalilea/samba ```  

### Configuración
En el servidor LDAP tan sólo hay que descargar y añadir un schema específico para SAMBA en /etc/openldap/schema y cargarlo en 
slapd.conf con la línea de configuración `include /etc/openldap/schema/samba.schema`. Esto es lo que nos 
permitirá almacenar los datos de SAMBA en la base de datos LDAP.  
En el servidor SAMBA hay que:
* Instalar los paquetes samba y samba-client para que actue como servidor y cliente SAMBA, y smbldap-tools para 
configurar LDAP para que utilice LDAP como backend.
* Configurar la conexión con LDAP usando las herramientas authconfig y nsswitch
* Arrancar los servicios para LDAP nscd y nslcd. Se hace en este momento porque si no al asignar permisos a los 
directorios de los shares podemos tener problemas (por ejemplo al crear un share con el home del usuario LDAP pere) 
* Configurar los shares (creamos directorios y archivos compartidos, modificamos /etc/samba/smb.conf, establecemos las 
configuraciones para compartirlos) y la integración SAMBA-LDAP
  * En /etc/samba/smb.conf definimos el backend LDAP incluyendo  
  ```passdb backend = ldapsam:ldap://ldap``` 
  y una serie de líneas con los sufijos que se usarán en LDAP para 
  guardar los nuevos usuarios, grupos, hosts y otras configuraciones necesarias.
  * En /etc/smbldap-tools/smbldap.conf especificamos dónde se encuentra el servidor LDAP master y slave (en nuestro 
  caso ambos son el mismo), establecemos el sufijo LDAP como 'dc=edt,dc=org' y los sufijos de los distintos tipos de 
  elemento ('ou=usuaris,dc=edt,dc=org' 'ou=grups,dc=edt,dc=org'...)  
* Guardar la contraseña del administrador (root) de SAMBA y LDAP con la herramienta smbpasswd (secret), de modo que 
SAMBA pueda usarla
* Crear en LDAP las estructuras de datos necesarias para almacenar la información de SAMBA mediante la utilidad 
smbldap-populate. Esta herramienta también pide que introduzcamos la clave del usuario root del dominio (en nuestro caso 
edt.org, la clave queda almacenada en LDAP)
* Crear los usuarios locales y de SAMBA mediante la herramienta smbpasswd
* Arrancar los servicios para SAMBA (smbd y nmbd). Se hace en último lugar en vez de arrancarlos a la vez que LDAP 
porque algunas configuraciones de los shares requieren conexión con LDAP, y si el servicio SAMBA estuviera arrancado 
cuando hacemos esas configuraciones habría que reiniciarlo para que los cambios tengan efecto.  

### Comprobaciones
Para verificar que el servidor SAMBA tiene acceso a LDAP usamos
```
getent passwd
getent group
```
y verificamos que aparecen los usuarios y grupos de LDAP. Con la segunda orden podemos verificar que están presentes 
los grupos *Account Operators, Print Operators, Backup Operators* y *Replicators*, creados durante el *populate* de la 
base de datos.  
Para comprobar que SAMBA está utilizando LDAP como backend, creamos un nuevo usuario con el comando
```bash
smbpasswd -a local01
```
y comprobamos que el nuevo usuario SAMBA aparece en LDAP con 
```ldapsearch -x -LLL -b 'uid=local01,ou=usuaris,dc=edt,dc=org'```  
Para comprobar que SAMBA está publicando los shares, ejecutamos `smbtree` e intentamos conectar a un share con
```
smbclient //SAMBA/public
smbclient -U pere //SAMBA/pere 
 ```
### Extra
se incluye en el repositorio de github un tercer directorio llamado hostsambapam. En él están los archivos necesarios 
para construir una imagen docker de un cliente samba-ldap-pam capaz de conectarse a los servidores LDAP y SAMBA. Desde 
este cliente un usuario LDAP puede loguearse al sistema, y al hacerlo se automontará en su HOME un directorio con su 
HOME de SAMBA (es decir, al loguear el usuario pere, en su home aparecerá un directorio llamado pere que corresponde al 
share SAMBA//pere, que sólo es accesible para él y que se desmontará al cerrar la sesión).   
   
La imágen de docker está en https://hub.docker.com/r/agalilea/hostsambapam y se puede descargar con
`docker pull agalilea/hostsambapam`
  
Para que esto sea posible hemos hecho lo siguiente:
En el cliente:
* Partimos de un Docker con el acceso a LDAP configurado y pam_mount instalado.
* Instalamos el paquete cifs-utils para poder montar los HOMES.
* Añadimos la siguiente linea en /etc/security/pam_mount.conf.xml  
```<volume user="*" fstype="cifs" server="samba" path="%(USER)"  mountpoint="~/%(USER)" />```  
* Modificamos el archivo /etc/pam.d/system-auth-edt para que monte el HOME del usuario cuando su uid sea >= 5000 (es 
decir, cuando sea usuario LDAP, ya que los locales empiezan en 1000)   

En el servidor SAMBA:
* creamos los directorios HOME de los usuarios LDAP que van a poder automontar su share y les cambiamos el propietario 
y grupo que corresponda a cada uno.
* creamos los shares de los HOMES en /etc/samba/smb.conf bajo el epígrafe [homes]
* creamos un usuario de SAMBA para cada usuario LDAP 

/etc/samba/smb.conf
```
[global]
        workgroup = MYGROUP
        server string = Samba Server Version %v
        log file = /var/log/samba/log.%m
        max log size = 50
        security = user
        passdb backend = ldapsam:ldap://ldap
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
[public]
        comment = Share publico
        path = /tmp/home/public
        public = yes
        browseable = yes
        writable = yes
        printable = no
guest ok = yes
```

### Documentación
https://help.ubuntu.com/lts/serverguide/samba-ldap.html.en  
https://github.com/edtasixm06/samba/blob/master/samba:18ldapsam/README.md
