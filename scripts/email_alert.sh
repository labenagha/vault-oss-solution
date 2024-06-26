#!/bin/bash
set -x

mailhub=$1
hostname=$2
AuthUser=$3
AuthPass=$4
email_body_content=$5
email_subject=$6
receipent_email=$7

smtp_install() {
    sudo apt update
    sudo apt install ssmtp mailutils -y
}

email_smtp() {
    sudo tee /etc/ssmtp/ssmtp.conf > /dev/null <<EOF
root=postmaster
mailhub=${mailhub}:587
hostname=${hostname}
AuthUser=${AuthUser}
AuthPass=${AuthPass}
FromLineOverride=YES
UseSTARTTLS=YES
EOF
}


echo ********** sending email **************
echo "${email_body_content}" | mail -s "${email_subject}" ${receipent_email}@${hostname}