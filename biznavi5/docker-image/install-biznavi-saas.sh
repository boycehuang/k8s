#!/bin/bash
set -e
INSTALL_ODOO_DIR=`pwd`

apt-get install -y moreutils

export BIZNAVI_DOCKER=${BIZNAVI_DOCKER:-"biznavi"}
export PERL_UPDATE_ENV="perl -p -e 's/\{\{([^}]+)\}\}/defined \$ENV{\$1} ? \$ENV{\$1} : \$&/eg' "

#### Detect type of system manager
export SYSTEM=''
pidof systemd && export SYSTEM='systemd'
pidof systemd-journald && export SYSTEM='systemd'
[[ -z $SYSTEM ]] && whereis upstart | grep -q 'upstart: /' && export SYSTEM='upstart'
[[ -z $SYSTEM ]] &&  export SYSTEM='supervisor'
echo "SYSTEM=$SYSTEM"

DAEMON_LIST=( "odoo" )
if [[ "$SYSTEM" == "systemd" ]]            ###################################### IF
 then
     ### CONTROL SCRIPTS - systemd

     cd /lib/systemd/system/

     for DAEMON in ${DAEMON_LIST[@]}
     do
         cp /opt/biznavi/biznavi.service biznavi.service
         eval "${PERL_UPDATE_ENV} < biznavi.service" | sponge biznavi.service
         ## START - systemd
         systemctl enable biznavi.service
         echo "systemctl restart biznavi.service"
     done

 elif [[ "$SYSTEM" == "upstart" ]]          #################################### ELIF
 then
     ### CONTROL SCRIPTS - upstart

     mkdir -p /etc/init && cd /etc/init/
     for DAEMON in ${DAEMON_LIST[@]}
     do
         cp /opt/biznavi/biznavi-init.conf biznavi.conf
         eval "${PERL_UPDATE_ENV} < biznavi.conf" | sponge biznavi.conf
         ## START - upstart
         echo "start biznavi"
         echo "stop biznavi"
         echo "restart biznavi"
     done
 else                                       #################################### ELSE
     ### CONTROL SCRIPTS - supervisor

     cd /etc/supervisor/conf.d/
     for DAEMON in ${DAEMON_LIST[@]}
     do
         cp /opt/biznavi/biznavi-supervisor.conf biznavi.conf
         eval "${PERL_UPDATE_ENV} < biznavi.conf" | sponge biznavi.conf
         ## START - supervisor
         supervisorctl reread
         supervisorctl update
         echo "supervisorctl start biznavi"
         echo "supervisorctl stop biznavi"
         echo "supervisorctl restart biznavi"
     done
 fi                                         ################################   END IF
