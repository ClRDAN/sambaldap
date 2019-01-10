# ldapserver:18samba

Podeu trobar les imatges docker al Dockehub de [edtasixm06](https://hub.docker.com/u/edtasixm06/)

Podeu trobar la documentació del mòdul a [ASIX-M06](https://sites.google.com/site/asixm06edt/)


## @edt ASIX M06-ASO Curs 2018-2019

Servidor ldap amb edt.org, que incorpora l'schema samba, per poder fer el populates de dades samba i ser utilitzat
com a backend **ldapsam** del servidor samba.


```
$ docker run --rm --name ldap -h ldap --net sambanet -d edtasixm06/ldapserver:18samba
```
