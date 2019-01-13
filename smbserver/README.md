#SAMBA
Archivos necesarios para generar una imagen docker con la que montar containers de 
Fedora 27 con un servidor SAMBA capaces de comunicarse con un container LDAP que haga de backend, permitiendo loguear y 
acceder a shares a usuarios LDAP y locales. 

La imagen ya creada se encuentra en https://hub.docker.com/r/agalilea/samba
```docker pull agalilea/samba```
La imagen ya creada del host se encuentra en https://hub.docker.com/r/agalilea/  
```docker pull agalilea/hostsambapam```  
La imagen del servidor LDAP se encuentra en https://hub.docker.com/r/agalilea/ldapsmb/  
```docker pull agalilea/ldapsmb```  


El repositorio contiene los siguientes archivos:
  * authconfig.conf: script que utiliza el comando authconfig para configurar la conexión con LDAP. Se ejecuta automáticamente al arrancar el container.  
  * Dockerfile: archivo de creación de la imagen Docker. Este archivo hace que se instalen en el container los paquetes 
  necesarios (samba samba-client openldap-clients nss-pam-ldapd authconfig smbldap-tools). También copia todos los 
  archivos de configuración al container y establece el script startup.sh como comando predeterminado a ejecutar al 
  arrancar el container.  
  * install.sh: script que se ejecuta al arrancar la imagen, configura el container y arranca servicios necesarios (nslcd para LDAP, sshd para SSH)  
  * nsswitch.conf: archivo de configuracion de nsswitch, sobrescribe al predefinido al ejecutar install.sh. Necesario para la comunicación con LDAP.  
  * populate.ldif: archivo con los objetos LDAP necesarios para poder almacenar la información de SAMBA en la base de datos LDAP.  
  * smb.conf: archivo con la configuración de los shares de SAMBA. En este archivo debe especificarse que se va a usar 
  LDAP como backend incluyendo el texto siguiente dentro del apartado [global]
  ```     
          passdb backend = ldapsam:ldap://ldap
          ldap suffix = dc=edt,dc=org
          ldap user suffix = ou=usuaris
          ldap group suffix = ou=grups
          ldap machine suffix = ou=hosts
          ldap idmap suffix = ou=domains
          ldap admin dn = cn=Manager,dc=edt,dc=org
          ldap ssl = no
          ldap passwd sync = yes
  ```
  * smbldap_bind.conf: archivo de configuración del usuario administrador de LDAP para SAMBA, almacena el dn y 
  contraseña de los usuarios administradores de los servidores LDAP maestro y esclavo. Si sólo hay un servidor LDAP 
  (nuestro caso), se usa el mismo usuario/password para maestro y esclavo. Este archivo sobreescribe al original en 
  /etc/smbldap-tools/ al arrancar el container.  
  * smbldap.conf: archivo de configuración de SAMBA que define la conexión con el backend LDAP. En él debemos 
  especificar el servidor LDAP a utilizar (en nuestro caso masterLDAP="ldap://ldap"), asegurarnos de que no se utiliza 
  TLS (ldapTLS="0") el sufijo de la base de datos LDAP (suffix="dc=edt,dc=org) y de varios grupos de elementos 
  importantes que también han sido definidos en smb.conf(usuarios en 'ou=usuaris,${suffix}', hosts en 
  'ou=hosts,${suffix}'), groups en ou=grups,${suffix}, entradas de IDMap en ou=domains,${suffix}. El resto se deja con 
  la configuración por defecto. Este archivo sustituye al predeterminado en /etc/smbldap-tools/ al arrancar el container.  
  * startup.sh: llama al script install.sh y especifica el programa padre al arrancar el container.  

