#HOSTSAMBAPAM
Archivos necesarios para generar una imagen docker con la que montar containers de 
Fedora 27 capaces de comunicarse con un container LDAP y SAMBA, permitiendo loguear a usuarios LDAP y locales. A los 
usuarios de LDAP se les automonta un directorio HOME mediante SAMBA y PAM.

La imagen ya creada se encuentra en https://hub.docker.com/r/agalilea/  
```docker pull agalilea/hostsambapam```  
La imagen del servidor LDAP se encuentra en https://hub.docker.com/r/agalilea/ldapsmb/  
```docker pull agalilea/ldapsmb```  
La imagen del servidor SAMBA se encuentra en https://hub.docker.com/r/agalilea/samba
```docker pull agalilea/samba```

El repositorio contiene los siguientes archivos:
  * authconfig.conf: script que utiliza el comando authconfig para configurar la conexión con LDAP. Se ejecuta automáticamente al arrancar el container.  
  * Dockerfile: archivo de creación de la imagen Docker. Este archivo hace que se instalen en el container los paquetes 
  necesarios para la comunicación con el servidor LDAP (openldap-clients, nss-pam-ldapd, authconfig) y para montar los 
  shares (pam_mount cifs-utils samba-client. También copia todos los archivos de configuración al container y establece 
  el script startup.sh como comando predeterminado a ejecutar al arrancar el container.  
  * install.sh: script que se ejecuta al arrancar la imagen, configura el container y arranca servicios necesarios 
  (nslcd y nscd para LDAP)  
  * nsswitch.conf: archivo de configuracion de nsswitch, sobrescribe al predefinido al ejecutar install.sh. Necesario para la comunicación con LDAP.  
  * pam_mount.conf.xml: archivo de configuración del módulo PAM pam_mount, necesario para montar los HOME compartidos 
  mediante el servidor SAMBA 
  * startup.sh: llama al script install.sh y especifica el programa padre al arrancar el container.  
  * system-auth.edt: archivo de módulos pam para la autenticación de usuarios, se encarga de controlar dicha
autenticación y de que se cree y/o monte automáticamente el HOME del usuario si no existía. Al arrancar el container este archivo se copia en /etc/pam.d/ y se crea un enlace simbólico llamado /etc/pam.d/system-auth que apunta a él.  

