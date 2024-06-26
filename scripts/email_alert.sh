#!/bin/bash
set -x
set -e


AuthPass=$1
email_body_content=$2
email_subject=$3
receipent_email=$4

sudo apt update -y

if ! sudo apt-get install ssmtp mailutils -y; then
    echo "Failed to install ssmtp and mailutils."
    exit 1
fi


sudo tee /etc/ssmtp/ssmtp.conf > /dev/null <<EOF
    root=postmaster
    mailhub=smtp.gmail.com:587
    hostname=gmail.com
    AuthUser=lbenagha@gmail.com
    AuthPass=${AuthPass}
    FromLineOverride=YES
    UseSTARTTLS=YES
EOF

echo ********** sending email **************
echo "${email_body_content}" | mail -s "${email_subject}" "${receipent_email}"