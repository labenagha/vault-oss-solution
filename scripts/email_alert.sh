#!/bin/bash
set -x
set -e

USER="ubuntu"
AuthPass=$1
receipent_email=$2
email_subject=$3
email_body_file=$4
sender_email=$5

email_body_content=$(cat "$email_body_file")

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
    logfile        $HOME/msmtp_logs/msmtp.log

    account        yahoo
    host           smtp.mail.yahoo.com
    port           587
    from           ${sender_email}
    user           ${sender_email}
    password       ${AuthPass}

    account default : yahoo
EOF
}
email_smtp

# Set permissions for msmtprc
sudo chmod 600 /etc/msmtprc

# Send the email using msmtp
echo -e "To: ${receipent_email}\nFrom: ${sender_email}\nSubject: ${email_subject}\n\n${email_content}" | msmtp --debug --from=${sender_email} ${receipent_email} 2>&1 | tee $HOME/msmtp_logs/msmtp.log
