#!/bin/dash
#################################################################################################
#################################################################################################
####										 	     ####
####		This script will restore all essential data of an Owncloud instance.         ####
####		Version: 1.0							 	     ####
####		For more information visit:					 	     ####
####		https://github.com/gtntdev/owncloud-backup-and-restore-client	 	     ####
####										 	     ####
#################################################################################################
#################################################################################################

#local parameters - static from backup
backup_root="/external_storage/lukas_tremmel/owncloud-backup-client/" # static from backup
short_domain="LTR" # static from backup

##remote parameters
#ssh - possibly new server (for example when moving oc)
ssh_host="www.example.com"
ssh_oc_base="/root/of/owncloud/"
ssh_user="my_user"
ssh_pw="my_password"

#db (mysql assumed) - possibly new db
db_host="db.example.com"
db_user="db_user"
db_pw="db_pw"
db_name="db_name"
db_port="3306" # not used for now
db_backup_location_relative="db_backup/" #static - don't change

#internal params
config_up_to_date=false # not used for now

# later do checks like 'test read/write permission of $bachup_root' here, encode pw, ...

# check wether 'config.php.on' and 'config.php.off' in 'maintenance_mode/restore/' exist and if they're up to date
if  test -n "$(find ${backup_root}maintenance_mode/restore/  -name 'config.php.on' -print -quit)" &&
    test -n "$(find ${backup_root}maintenance_mode/restore/  -name 'config.php.off' -print -quit)"; then
    echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - config files exist."
    #for now we believe they're up to date, otherwise we would know
    config_up_to_date=true
    echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - config files are up to date."
else
    #fetch the config.php file and mod it to fit 'config.php.on' and 'config.php.off' accordingly
    /usr/bin/rsync -ratlz --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
        ${ssh_host}:${ssh_oc_base}config/config.php ${backup_root}maintenance_mode/restore/config.php.off
    echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - config file 'config.php.off' successfully imported."
    #convert 'config.php.off' to 'config.php.on'
    ${backup_root}helpers/./convert ${backup_root}maintenance_mode/restore/config.php.off ${backup_root}maintenance_mode/restore/config.php.on
    echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - config file successfully converted to 'config.php.on'."
fi

# put the OC instance in maintenance mode
/usr/bin/rsync -ratlz --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
    ${backup_root}maintenance_mode/restore/config.php.on ${ssh_host}:${ssh_oc_base}config/config.php
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - OC Sercer is now in maintenane mode."

# Wait a few minutes till every Client got the notice - todo: progress bar
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - Waiting a while till every client got notified."
sleep 30s
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - Moving on..."

## Sync Data - remove data dir in remote location
#  config dir - not for now, because maintenance mode would be disabled
#echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Transfering 'config' ..."
#/usr/bin/rsync -ratlz --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
#        ${backup_root}config ${ssh_host}:${ssh_oc_base}
#echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Transfering 'config' finished"
#  data dir
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Transfering 'data' ..."
/usr/bin/rsync -ratlz --info=progress2 --info=name0 --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
        ${backup_root}data ${ssh_host}:${ssh_oc_base}
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Transfering 'data' finished"

## Restore database
# sync db - for now cp db_backup/'latest' db_backup/dbrestore.bak
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Restoring db to remote storage ..."
/usr/bin/rsync -ratlz --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
    ${backup_root}db_backup/dbrestore.bak ${ssh_host}:${ssh_oc_base}dbrestore.bak
# import db
sshpass -p ${ssh_pw} ssh -o StrictHostKeyChecking=no ${ssh_user}@${ssh_host} \
    "mysql -h ${db_host} -u ${db_user} -p${db_pw} ${db_name}" \
    < ${external_storage}db_backup/dbrestore.bak
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Syncing Mode - Restoring db finished"

# disable maintenance mode
## Owncloud official document stated to copy whole backedup config folder to new instance -> for now copy with maintenanced mode turned on and edit db manually
/usr/bin/rsync -ratlz --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
    ${backup_root}maintenance_mode/config.php.on ${ssh_host}:${ssh_oc_base}config/config.php
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:Maintenance Mode - OC Server: maintenance mode is now disabled again. [DEV]not in this version[\\DEV]"

# finished
echo "[$(date +"%Y.%m.%d::%H:%M:%S")]:OWNCLOUD BACKUP CLIENT - UPDATE SUCCESSFUL!"

exit 0
