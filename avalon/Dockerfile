FROM        phusion/passenger-ruby25
LABEL       maintainer="Michael B. Klein <michael.klein@northwestern.edu>, Phuong Dinh <pdinh@indiana.edu>"

RUN         curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
         && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
         && curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN         apt-get update && apt-get install -y \
            mediainfo \
            ffmpeg \
            x264 \
            cmake \
            pkg-config \
            lsof \
            sendmail \
            yarn \
            nodejs \
            imagemagick \
         && rm -rf /var/lib/apt/lists/* \
         && apt-get clean
RUN         ln -s /usr/bin/lsof /usr/sbin/ && \
            rm /etc/nginx/sites-enabled/default && \
            rm -f /etc/service/nginx/down && \
            ln -s /etc/nginx/sites-available/avalon /etc/nginx/sites-enabled/avalon && \
            chown app:docker_env /etc/container_environment.sh
ARG         AVALON_REPO=https://github.com/WGBH-MLA/mlavalon.git
ARG         AVALON_BRANCH=master
# ARG         AVALON_BRANCH=chrono-mars-ingest-dates
WORKDIR     /home/app

ADD https://api.github.com/repos/WGBH-MLA/mlavalon/git/refs/heads/$AVALON_BRANCH version.json
RUN         git clone --branch=${AVALON_BRANCH} --depth=1 ${AVALON_REPO} avalon

WORKDIR     /home/app
RUN         chown -R app:app /home/app/avalon

USER        app
ADD         Gemfile.local /home/app/avalon/
ADD         config /home/app/avalon/config/
ARG         RAILS_ENV=production
RUN         cd avalon && \
            # gem update --system && \
              gem install bundler -v 2.3.27 && \
              bundle config build.nokogiri --use-system-libraries && \
              bundle install --path=vendor/gems --deployment && \
              cd ..
ARG         BASE_URL
ARG         DATABASE_URL
WORKDIR     /home/app/avalon
RUN         yarn cache clean && rm -rf ./node_modules

WORKDIR /home/app/avalon
RUN mkdir -p tmp/pids 
RUN touch log/production.log 
RUN ls -alh log 
RUN bundle exec whenever -w -f config/docker_schedule.rb 
RUN SECRET_KEY_BASE=$(ruby -r 'securerandom' -e 'puts SecureRandom.hex(64)') bundle exec rails assets:precompile

USER        root
ADD         ./avalon.conf /etc/nginx/sites-available/avalon
ADD         ./nginx_env.conf /etc/nginx/main.d/env.conf
ADD         rails_init.sh /etc/my_init.d/30_rails_init.sh
ADD         ./profile /etc/profile
RUN         mkdir /streamfiles && chmod 0777 /streamfiles


# add watchfolder cron
COPY watch_folder_task /var/spool/cron/crontabs/root
RUN chmod +x /home/app/avalon/script/watch_folder.rb
RUN chmod +x /home/app/avalon/script/watch_folder.sh

# RUN chmod 0644 /etc/cron.d/watch_folder_task
RUN touch /var/log/avalon-cron.log

RUN apt-get update && apt-get install -y vim

VOLUME      /streamfiles

CMD service cron start
