#!/bin/bash
set -x
set -e

USER="ubuntu"
AuthPass=$1
email_body_content=$2
email_subject=$3
receipent_email=$4

sudo apt update -y

if ! sudo apt-get install msmtp mailutils -y; then
    echo "Failed to install msmtp and mailutils."
    exit 1
fi


email_smtp() {
sudo tee /etc/msmtprc > /dev/null <<EOF
    defaults
    auth           on
    tls            on
    tls_trust_file /etc/ssl/certs/ca-certificates.crt
    logfile        ~/.msmtp.log

    account        yahoo
    host           smtp.mail.yahoo.com
    port           587
    from           lbenagha@yahoo.com
    user           lbenagha@yahoo.com
    password       ${AuthPass}

    account default : yahoo
EOF
}
email_smtp

# Set permissions for msmtprc
sudo chmod 600 /etc/msmtprc

# Send the email using msmtp
echo -e "To: ${receipent_email}\nFrom: lbenagha@yahoo.com\nSubject: ${email_subject}\n\n${email_body_content}" | msmtp --debug --logfile /tmp/msmtp.log --from=lbenagha@yahoo.com ${receipent_email}