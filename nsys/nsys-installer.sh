#!/bin/bash

##########################################################################
#                                                                        #
# Nsys Platform Installation Script                                      #
# Copyright 2015, 2018 Nsys.org - Tomas Hrdlicka <tomas@hrdlicka.co.uk>  #
# All rights reserved.                                                   #
#                                                                        #
# Web: code.nsys.org                                                     #
# Git: github.com/nsys-code/nsys-scripts                                 #
#                                                                        #
##########################################################################

NSYS_USER=nsys
NSYS_GROUP=$NSYS_USER
NSYS_BASEDIR=/opt/nsys
NSYS_HOME=/var/nsys/application-data
NSYS_BUNDLE_FILE=nsys-bundle.zip
NSYS_BUNDLE_PATH=/tmp/$NSYS_BUNDLE_FILE
NSYS_BUNDLE_FORCE_DOWNLOAD=false
NSYS_CLOUD_URL=http://cloud.nsys.org
NSYS_REINSTALL=false

checkJava() {
    echo "Detecting Java installation..."
    echo

    # Find whether JAVA executable exists
    if [ -x $JAVA_HOME/bin/java ]; then
        JAVA=$JAVA_HOME/bin/java
    else
        JAVA=$(which java)
    fi

    if [ "x$JAVA" = "x" ]; then
        echo "Java executable not found (hint: set JAVA_HOME)" >&2
        echo
        exit 1
    fi

    echo "Java executable found:	$JAVA"
    echo "Using JAVA_HOME:      	$JAVA_HOME"
    echo
}

checkPrerequisites() {
    checkJava

    DCMD=$(which curl)

    if [ ! -x "$DCMD" ]; then
        echo "Unable to find command 'curl'! Trying to find command 'wget'..."
        echo

        DCMD=$(which wget)

        if [ ! -x "$DCMD" ]; then
            echo "Unable to find command 'wget'!"
            echo
            echo "Please install command 'curl' or 'wget' to download the Nsys Platform bundle."
            echo
            exit 1
        fi

        DOWNLOAD_CMD=$DCMD
        DOWNLOAD_CMD_OPTS="-O"
    else
        DOWNLOAD_CMD=$DCMD
        DOWNLOAD_CMD_OPTS="-o"
    fi

    echo "Download executable found: $DOWNLOAD_CMD"
    echo

    if [ -e $NSYS_BASEDIR/bin/nsys-launcher.sh ] && [ ! "$NSYS_REINSTALL" = "true" ]; then
        echo "Nsys Platform installation detected in folder '$NSYS_BASEDIR'!"
        echo "Before you can continue you need to uninstall current version."
        echo "You can use option '--reinstall' that create a bakup of previous version"
        echo "and start installation of latest version."
        echo
        echo "Run command '$0 --help' to see all available options."
        echo
        echo "Terminating script..."
        echo
        exit 1
    fi
}

createSystemUser() {
    NSYS_GROUP_COUNT=`cat /etc/group | grep $NSYS_GROUP | wc -l`

    if [ $NSYS_GROUP_COUNT -gt 0 ]; then
        echo "User group '$NSYS_GROUP' created already! Skipping..."
    else
        echo "Creating user group '$NSYS_GROUP'..."
        addgroup $NSYS_GROUP
    fi

    NSYS_USER_COUNT=`cat /etc/passwd | grep $NSYS_USER | wc -l`

    if [ $NSYS_USER_COUNT -gt 0 ]; then
        echo "System user account '$NSYS_USER' created already! Skipping..."
        return 0
    fi

    echo "Creating system user account '$NSYS_USER'..."
    adduser --system --shell /bin/bash --gecos 'Nsys Platform Control' --ingroup $NSYS_GROUP --disabled-password --home $NSYS_BASEDIR $NSYS_USER
}

downloadNsysBundle() {
    if [ -e "$NSYS_BUNDLE_PATH" ] && [ ! "$NSYS_BUNDLE_FORCE_DOWNLOAD" = "true" ]; then
        echo
        echo "Nsys Platform bundle found in file '$NSYS_BUNDLE_PATH'! Skipping downloading..."
        echo
        return 0
    fi

    echo
    echo "Downloading Nsys Platform bundle..."
    echo

    $DOWNLOAD_CMD $DOWNLOAD_CMD_OPTS $NSYS_BUNDLE_PATH $NSYS_CLOUD_URL/download/$NSYS_BUNDLE_FILE

    echo
    echo "Saved to $NSYS_BUNDLE_PATH"
    echo
}

installNsysBundle() {
    CURRENT_DIR=`pwd`

    cd $NSYS_BASEDIR

    if [ "$(ls -A $NSYS_BASEDIR)" ]; then
        NSYS_BACKUP_DIR=$NSYS_BASEDIR/.backup
        mkdir -p $NSYS_BACKUP_DIR
        mkdir -p $NSYS_BASEDIR/bin/etc/init.d

        cp /etc/init.d/nsys-daemon $NSYS_BASEDIR/bin/etc/init.d
        cp /etc/init.d/nsys-portal $NSYS_BASEDIR/bin/etc/init.d

        NOW=$(date +"%Y-%m-%d_%H-%M-%S")
        NSYS_BACKUP_FILE="nsys-backup_$NOW.tar.gz"

        echo "Backuping previous installation of the Nsys Platform..."
        echo

        tar -zc --exclude=.backup -f $NSYS_BACKUP_FILE .
        mv $NSYS_BACKUP_FILE $NSYS_BACKUP_DIR

        echo
        echo "Backup available in $NSYS_BACKUP_DIR/$NSYS_BACKUP_FILE"
        echo
        echo "Removing previous installation..."
        echo

        rm -rf $NSYS_BASEDIR/*
    fi

    echo "Installing Nsys Platform bundle to folder '$NSYS_BASEDIR'..."
    echo

    cp $NSYS_BUNDLE_PATH $NSYS_BASEDIR
    unzip -q $NSYS_BUNDLE_FILE
    mkdir -p $NSYS_BASEDIR
    mkdir -p $NSYS_HOME
    chown -R $NSYS_USER:$NSYS_GROUP $NSYS_BASEDIR
    chown -R $NSYS_USER:$NSYS_GROUP $NSYS_HOME
    chmod -R 755 $NSYS_BASEDIR/bin/*.sh
    chmod -R 755 $NSYS_BASEDIR/portal/bin/*.sh
    chmod -R 775 $NSYS_BASEDIR/portal/webapps
    rm $NSYS_BUNDLE_FILE

    cd $CURRENT_DIR

    NSYS_DAEMON_ENV_SCRIPT=$NSYS_BASEDIR/bin/nsys-daemon.env.sh
    NSYS_HOME_DAEMON="NSYS_HOME=\"${NSYS_HOME}/daemon\""
    NSYS_CONFIG_DAEMON="NSYS_CONFIG=\"${NSYS_BASEDIR}/conf/nsys.cfg\""
    LOG4J_CONFIG_DAEMON="LOG4J_CONFIG=\"${NSYS_BASEDIR}/conf/log4j.xml\""

    sed -i "7s@.*@$(echo $NSYS_HOME_DAEMON)@" $NSYS_DAEMON_ENV_SCRIPT
    sed -i "13s@.*@$(echo $NSYS_CONFIG_DAEMON)@" $NSYS_DAEMON_ENV_SCRIPT
    sed -i "19s@.*@$(echo $LOG4J_CONFIG_DAEMON)@" $NSYS_DAEMON_ENV_SCRIPT

    NSYS_PORTAL_ENV_SCRIPT=$NSYS_BASEDIR/bin/nsys-portal.env.sh
    NSYS_HOME_PORTAL="NSYS_HOME=\"${NSYS_HOME}/portal\""
    NSYS_CONFIG_PORTAL="NSYS_CONFIG=\"${NSYS_BASEDIR}/conf/nsys-portal.cfg\""
    LOG4J_CONFIG_PORTAL="LOG4J_CONFIG=\"${NSYS_BASEDIR}/conf/log4j-portal.xml\""

    sed -i "8s@.*@$(echo $NSYS_HOME_PORTAL)@" $NSYS_PORTAL_ENV_SCRIPT
    sed -i "14s@.*@$(echo $NSYS_CONFIG_PORTAL)@" $NSYS_PORTAL_ENV_SCRIPT
    sed -i "20s@.*@$(echo $LOG4J_CONFIG_PORTAL)@" $NSYS_PORTAL_ENV_SCRIPT

    NSYS_DAEMON_CLI_ENV_SCRIPT=$NSYS_BASEDIR/bin/nsys-daemon-cli.env.sh
    NSYS_CONFIG_DAEMON_CLI="NSYS_CONFIG=\"${NSYS_BASEDIR}/conf/nsys-cli.cfg\""
    LOG4J_CONFIG_DAEMON_CLI="LOG4J_CONFIG=\"${NSYS_BASEDIR}/conf/log4j-cli.xml\""

    sed -i "7s@.*@$(echo $NSYS_CONFIG_DAEMON_CLI)@" $NSYS_DAEMON_CLI_ENV_SCRIPT
    sed -i "13s@.*@$(echo $LOG4J_CONFIG_DAEMON_CLI)@" $NSYS_DAEMON_CLI_ENV_SCRIPT

    NSYS_RUNAS_SCRIPT="RUN_AS=\"${NSYS_USER}\""
    NSYS_BASEDIR_SCRIPT="NSYS_BASEDIR=\"${NSYS_BASEDIR}\""

    NSYS_DAEMON_SCRIPT=$NSYS_BASEDIR/bin/nsys-daemon.sh
    sed -i "16s@.*@$(echo $NSYS_RUNAS_SCRIPT)@" $NSYS_DAEMON_SCRIPT
    sed -i "20s@.*@$(echo $NSYS_BASEDIR_SCRIPT)@" $NSYS_DAEMON_SCRIPT

    NSYS_PORTAL_SCRIPT=$NSYS_BASEDIR/bin/nsys-portal.sh
    sed -i "16s@.*@$(echo $NSYS_RUNAS_SCRIPT)@" $NSYS_PORTAL_SCRIPT
    sed -i "20s@.*@$(echo $NSYS_BASEDIR_SCRIPT)@" $NSYS_PORTAL_SCRIPT

    NSYS_DAEMON_CLI_SCRIPT=$NSYS_BASEDIR/bin/nsys-daemon-cli.sh
    sed -i "5s@.*@$(echo $NSYS_BASEDIR_SCRIPT)@" $NSYS_DAEMON_CLI_SCRIPT

    cp $NSYS_BASEDIR/bin/nsys-daemon.sh /etc/init.d/nsys-daemon
    cp $NSYS_BASEDIR/bin/nsys-portal.sh /etc/init.d/nsys-portal
    chmod a+x /etc/init.d/nsys-daemon
    chmod a+x /etc/init.d/nsys-portal

    echo "Nsys Platform has been installed successfully!"
    echo
    echo "To run Nsys Daemon use command:"
    echo "     # /etc/init.d/nsys-daemon run"
    echo
    echo "To run Nsys Portal use command:"
    echo "     # /etc/init.d/nsys-portal run"
    echo
}

runScriptAsService() {
    if [ ! -e /etc/init.d/$1 ]; then
        echo "Service '$1' not found in /etc/init.d!"
        echo
        exit 1
    fi

    update-rc.d $1 defaults
}

appHeader() {
    echo
    echo "Nsys Platform Installation Script"
    echo "Copyright 2015, 2018 Nsys.org - Tomas Hrdlicka <tomas@hrdlicka.co.uk>"
    echo "All rights reserved."
    echo
    echo "Web: code.nsys.org"
    echo "Git: github.com/nsys-code/nsys-scripts"
    echo
    echo "More information about installation and configuration you can find at"
    echo "http://doc.nsys.org/display/NSYS/Nsys+Installation+and+Configuration"
    echo
}

appHelp() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "    -u, --nsys-user USER     Nsys Platform Control system user acount"
    echo "    -g, --nsys-group GROUP   Nsys Platform Control system user group"
    echo "    -b, --nsys-basedir DIR   Nsys Platform installation directory (e.g. /opt/nsys)"
    echo "    -h, --nsys-home DIR      Nsys Platform home directory for application data"
    echo "                             (e.g. /var/nsys/application-data)"
    echo "        --reinstall          Uninstall current version of Nsys Platform,"
    echo "                             then continue with installation of latest version."
    echo "                             Backup of previous installation is available in"
    echo "                             folder \$NSYS_BASEDIR/.backup"
    echo "        --force-download     Download latest version of the bundle everytime"
    echo "        --cfg-daemon-srv     Configure Nsys Daemon to run as service"
    echo "        --cfg-portal-srv     Configure Nsys Portal to run as service"
    echo "        --help               Show help and quit"
    echo
    echo "Examples:"
    echo "   # $0 --nsys-user nsys --nsys-group nsys \\"
    echo "     --nsys-basedir /opt/nsys --nsys-home /var/nsys/application-data"
    echo "   # $0"
    echo "   # $0 --reinstall"
    echo "   # $0 --reinstall --force-download"
    echo "   # $0 --cfg-daemon-srv"
    echo "   # $0 --cfg-portal-srv"
    echo
}

appHeader

if [ `whoami` != "root" ]; then
    echo "Privileges of user root are required to run this script!"
    echo
    exit 1
fi

while [[ $# -gt 0 ]]
do
    PARAM="$1"
    case $PARAM in
        -u|--nsys-user)
            if [ ! "x$2" = "x" ]; then
                NSYS_USER="$2"
            fi
            shift
            ;;

        -g|--nsys-group)
            if [ ! "x$2" = "x" ]; then
                NSYS_GROUP="$2"
            fi
            shift
            ;;

        -b|--nsys-basedir)
            if [ ! "x$2" = "x" ]; then
                NSYS_BASEDIR="$2"
            fi
            shift
            ;;

        -h|--nsys-home)
            if [ ! "x$2" = "x" ]; then
                NSYS_HOME="$2"
            fi
            shift
            ;;

        --reinstall)
            NSYS_REINSTALL=true
            ;;

        --force-download)
            NSYS_BUNDLE_FORCE_DOWNLOAD=true
            ;;

        --cfg-daemon-srv)
            runScriptAsService nsys-daemon
            exit 0
            ;;

        --cfg-portal-srv)
            runScriptAsService nsys-portal
            exit 0
            ;;

        --help)
            appHelp
            exit 0
            ;;

        *)
            echo "Unknown option '$PARAM'!"
            echo
            echo "Run command '$0 --help' to see all available options."
            echo
            exit 1
            ;;
    esac
    shift
done

echo "Using NSYS_USER:      $NSYS_USER"
echo "Using NSYS_GROUP:     $NSYS_GROUP"
echo "Using NSYS_BASEDIR:   $NSYS_BASEDIR"
echo "Using NSYS_HOME:      $NSYS_HOME"
echo

checkPrerequisites

createSystemUser

downloadNsysBundle

installNsysBundle

exit $?
