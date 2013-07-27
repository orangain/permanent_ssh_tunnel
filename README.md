permanent_ssh_tunnel
====================

A [Fabric](http://fabfile.org) fabfile to setup a **permanent** SSH tunnel between two servers easily using [Autossh](http://www.harding.motd.ca/autossh/).

Prerequirements
---------------

* Client
    * OS is Ubuntu.
* Server
    * OS is Debian based.
* Workstation
	* Can log into both client and server via ssh and login user can use `sudo`.
	* Python and virutalenv is installed.
	
Usage
-----

Main command to setup a tunnel is:

```
fab setup:<client>,<server>,local_port=<local_port>,remote_port=<remote_port>,…
```

Full example to setup a tunnel for MySQL:

```
$ git clone https://github.com/orangain/permanent_ssh_tunnel.git
$ cd permanent_ssh_tunnel
$ virtualenv venv
$ . venv/bin/activate
$ pip install -r requiements.txt
$ fab setup:client,server,local_port=33306,remote_port=3306
```
