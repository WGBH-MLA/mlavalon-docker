#!/bin/bash

# sendmail needs this to work
line=$(head -n 1 /etc/hosts)
line2=$(echo $line | awk '{print $2}')
echo "$line $line2.localdomain" >> /etc/hosts
service sendmail start

# batch ingest cronjob wouldn't autorun without this
touch /var/spool/cron/crontabs/app

chmod 0777 -R /masterfiles
chown -R app /masterfiles
cd /home/app/avalon

# Bringing in the envars we need
# TODO: Something better?
env | sed 's#^#export #1;s#=#&"#1;s#$#"&#1' > /etc/profile.d/avalon_nginx_env

service nginx restart

su app
BACKGROUND=yes QUEUE=* bundle exec rake resque:work
BACKGROUND=yes bundle exec rake environment resque:scheduler
RAILS_ENV=production bundle exec rake db:setup
