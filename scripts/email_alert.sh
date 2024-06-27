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


email_smtp() {
    sudo tee /etc/ssmtp/ssmtp.conf > /dev/null <<EOF
        SERVER=lbenagha@yahoo.com
        mailhub=smtp.yahoo.com:587
        hostname=yahoo.com
        AuthUser=lbenagha@yahoo.com
        AuthPass=${AuthPass}
        FromLineOverride=YES
        rewriteDomain=yahoo.com
        UseSTARTTLS=YES
        UseTLS=YES
        AuthMethod=LOGIN
EOF
}
email_smtp

cat /etc/ssmtp/ssmtp.conf

echo ********** sending email **************
# echo -e "To: ${receipent_email}\nFrom: lbenagha@yahoo.com\nSubject: ${email_subject}\n\n${email_body_content}" | ssmtp ${receipent_email}
echo -e "To: ${receipent_email}\nFrom: lbenagha@yahoo.com\nSubject: ${email_subject}\n\n${email_body_content}" | ssmtp ${receipent_email}
