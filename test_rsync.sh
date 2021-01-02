#!/bin/dash

#local parameters
backup_root="/path/"
short_domain="my_dom" #choose freely -> part of db backup name

##remote parameters
#ssh
ssh_host="www.example.com"
ssh_oc_base="/root/of/owncloud/"
ssh_user="my_user"
ssh_pw="my_password"

/usr/bin/rsync -ratlz --rsh="/usr/bin/sshpass -p "${ssh_pw}" ssh -o StrictHostKeyChecking=no -l ${ssh_user}" \
    ${ssh_host}:${ssh_oc_base}config/config.php ${backup_root}maintenance_mode/config.php.off

exit 0
