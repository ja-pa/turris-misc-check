#!/usr/bin/python

import sys
import os
import smtplib
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText


def send_email(fromaddr, toaddr, subject, body, password, smptserver='smtp.seznam.cz'):
    msg = MIMEMultipart()
    msg['From'] = fromaddr
    msg['To'] = toaddr
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))
    server_ssl = smtplib.SMTP_SSL(smptserver, 465)
    server_ssl.ehlo()
    server_ssl.login(fromaddr, password)
    text = msg.as_string()
    server_ssl.sendmail(fromaddr, toaddr, text)
    server_ssl.quit()

if __name__ == "__main__":
    print len(sys.argv)
    if len(sys.argv) == 6:
        fromaddr, toaddr, password, subject, file_name=sys.argv[1:]
        if os.path.isfile(file_name):
            with open(file_name,"r") as fp:
                body=fp.read()
                print "Sending email..."
                send_email(fromaddr, toaddr, subject, body, password )
        else:
            print "Error file:",file_name," does not exist !"
    else:
        print "Help:"
        print "Mandatory arguments"
        print "from","to","password","subject","filecontent"
