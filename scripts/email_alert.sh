#!/bin/bash
set -x
set -e

mailhub=$1
hostname=$2
AuthUser=$3
AuthPass=$4
email_body_content=$5
email_subject=$6
receipent_email=$7

sudo apt update -y

if ! sudo apt-get install ssmtp mailutils -y; then
    echo "Failed to install ssmtp and mailutils."
    exit 1
fi


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

email_smtp

echo ********** sending email **************
echo "${email_body_content}" | mail -s "${email_subject}" ${receipent_email}@${hostname}