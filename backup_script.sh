#!/bin/dash
#################################################################################################
#################################################################################################
####										 	     ####
####		This script will back up all essential data of an Owncloud instance.         ####
####		Version: 1.0							 	     ####
####		For more information visit:					 	     ####
####		https://github.com/gtntdev/owncloud-backup-and-restore-client		     ####
####										 	     ####
#################################################################################################
#################################################################################################

#local parameters
backup_root="/path/"
short_domain="my_dom" #choose freely -> part of db backup name

##remote parameters
#ssh
ssh_host="www.example.com"
ssh_oc_base="/root/of/owncloud/"
ssh_user="my_user"
ssh_pw="my_password"

#db (mysql assumed)
db_host="db.example.com"
db_user="db_user"
db_pw="db_pw"
db_name="db_name"
db_port="3306" # not used for now
db_backup_location_relative="db_backup/" #static - don't change

#internal params
config_up_to_date=false # not used for now

# later do checks like 'test read/write permission of $bachup_root' here
# IMPORTANT later check if only valid chars are used in the pw, no ' char and no "euro" char

# check wether 'config.php.on' and 'config.php.off' in 'maintenance_mode' exist and if they're up to date
if  test -n "$(find ${backup_root}maintenance_mode/  -name 'config.php.on' -print -quit)" &&
    test -n "$(find ${backup_root}maintenance_mode/  -name 'config.php.off' -print -quit)"; then
    echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - config files exist."
    #for now we believe they're up to date, otherwise we would know
    config_up_to_date=true
    echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - config files are up to date."
else
    #fetch the config.php file and mod it to fit 'config.php.on' and 'config.php.off' accordingly
    /usr/bin/rsync -ratlz --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
        ${ssh_host}:${ssh_oc_base}config/config.php ${backup_root}maintenance_mode/config.php.off
    echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - config file 'config.php.off' successfully imported."
    #convert 'config.php.off' to 'config.php.on'
    ${backup_root}helpers/./convert ${backup_root}maintenance_mode/config.php.off ${backup_root}maintenance_mode/config.php.on
    echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - config file successfully converted to 'config.php.on'."
fi

# put the OC instance in maintenance mode
/usr/bin/rsync -ratlz --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
    ${backup_root}maintenance_mode/config.php.on ${ssh_host}:${ssh_oc_base}config/config.php
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - OC Sercer is now in maintenane mode."

# Wait a few minutes till every Client got the notice
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - Waiting a while till every client got notified."
sleep 3m
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - Moving on..."

## Sync Data
#  config dir
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Transfering 'config' ..."
/usr/bin/rsync -ratlz --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
        ${ssh_host}:${ssh_oc_base}config ${backup_root}
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Transfering 'config' finished"
#  data dir
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Transfering 'data' ..."
/usr/bin/rsync -ratlz --info=progress2 --info=name0 --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
        ${ssh_host}:${ssh_oc_base}data ${backup_root}
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Transfering 'data' finished"

## Dump database
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Dumping db to local storage ..."
sshpass -p ${ssh_pw} ssh -o StrictHostKeyChecking=no ${ssh_user}@${ssh_host} \
    "mysqldump --no-tablespaces --single-transaction -h ${db_host} -u ${db_user} -p${db_pw} ${db_name}"  \
              > ${external_storage}db_backup/owncloud-${short_domain}-dbbackup_`date +"%Y%m%d%H%M"`.bak
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Dumping db finished"

# disable maintenance mode
/usr/bin/rsync -ratlz --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
    ${backup_root}maintenance_mode/config.php.off ${ssh_host}:${ssh_oc_base}config/config.php
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - OC Sercer: maintenane mode is now disabled again."

# finished
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:OWNCLOUD BACKUP CLIENT - UPDATE SUCCESSFUL!"

exit 0
