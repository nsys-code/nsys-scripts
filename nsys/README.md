# Nsys Platform Scripts

## Quick links

* [Nsys Platform][1]
* [Nsys Code][2]
* [Nsys Installation and Configuration][3]

## Description

The Nsys Platform Scripts provide set of maintenance scripts for development, deployment and testing of the [Nsys Platform](https://nsys.org).

[1]: https://nsys.org
[2]: http://code.nsys.org
[3]: http://doc.nsys.org/display/NSYS/Nsys+Installation+and+Configuration

## How to install Nsys Platform on Unix/Linux

### Default installation (example # 1)

~~~~
# curl -sSL https://raw.githubusercontent.com/nsys-code/nsys-scripts/master/nsys/nsys-installer.sh | bash
~~~~

### Default installation (example # 2)

~~~~
# wget -qO- https://raw.githubusercontent.com/nsys-code/nsys-scripts/master/nsys/nsys-installer.sh | bash
~~~~

### Default installation (example # 3)

~~~~
# curl -o nsys-installer.sh https://raw.githubusercontent.com/nsys-code/nsys-scripts/master/nsys/nsys-installer.sh
# chmod a+x nsys-installer.sh
# ./nsys-installer.sh
~~~~

### Default installation (example # 4)

~~~~
# wget -O nsys-installer.sh https://raw.githubusercontent.com/nsys-code/nsys-scripts/master/nsys/nsys-installer.sh
# chmod a+x nsys-installer.sh
# ./nsys-installer.sh
~~~~

### Custom installation

~~~~
# curl -o nsys-installer.sh https://raw.githubusercontent.com/nsys-code/nsys-scripts/master/nsys/nsys-installer.sh
# chmod a+x nsys-installer.sh
# ./nsys-installer.sh --nsys-user nsys --nsys-group nsys --nsys-basedir /opt/nsys --nsys-home /var/nsys/application-data
~~~~

### Available options for nsys-installer.sh script

~~~~
# ./nsys-installer.sh --help

Nsys Platform Installation Script
Copyright 2015, 2017 Nsys.org - Tomas Hrdlicka <tomas@hrdlicka.co.uk>
All rights reserved.

Web: code.nsys.org
Git: github.com/nsys-code/nsys-scripts

More information about installation and configuration you can find at
http://doc.nsys.org/display/NSYS/Nsys+Installation+and+Configuration

Usage: ./nsys-installer.sh [OPTIONS]

Options:
    -u, --nsys-user USER     Nsys Platform Control system user acount
    -g, --nsys-group GROUP   Nsys Platform Control system user group
    -b, --nsys-basedir DIR   Nsys Platform installation directory (e.g. /opt/nsys)
    -h, --nsys-home DIR      Nsys Platform home directory for application data
                             (e.g. /var/nsys/application-data)
        --reinstall          Uninstall current version of Nsys Platform,
                             then continue with installation of latest version.
                             Backup of previous installation is available in
                             folder $NSYS_BASEDIR/.backup
        --force-download     Download latest version of the bundle everytime
        --cfg-daemon-srv     Configure Nsys Daemon to run as service
        --cfg-portal-srv     Configure Nsys Portal to run as service
        --help               Show help and quit

Examples:
   # ./nsys-installer.sh --nsys-user nsys --nsys-group nsys \
     --nsys-basedir /opt/nsys --nsys-home /var/nsys/application-data
   # ./nsys-installer.sh
   # ./nsys-installer.sh --reinstall
   # ./nsys-installer.sh --reinstall --force-download
   # ./nsys-installer.sh --cfg-daemon-srv
   # ./nsys-installer.sh --cfg-portal-srv
~~~~