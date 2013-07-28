permanent_ssh_tunnel
====================

A [Fabric](http://fabfile.org) fabfile to setup a *permanent* SSH tunnel between two servers easily.

![nodes](https://raw.github.com/orangain/permanent_ssh_tunnel/master/doc/nodes.png)

Prerequirements
---------------

* Client
    * OS is Ubuntu.
* Server
    * OS is Debian based.
* Workstation
	* Can login to both client and server via SSH and login user can `sudo`.
	* Python and virutalenv is installed.
	
Usage
-----

Main command to setup a tunnel is:

```
fab setup:<client>,<server>,local_port=<local_port>,remote_port=<remote_port>,…
```

Full example to setup a tunnel for MySQL from `dbclient:13306` to `dbserver:3306`:

```sh
$ git clone https://github.com/orangain/permanent_ssh_tunnel.git
$ cd permanent_ssh_tunnel
$ virtualenv venv
$ . venv/bin/activate
$ pip install -r requiements.txt
$ fab setup:dbclient,dbserver,local_port=13306,remote_port=3306
```
