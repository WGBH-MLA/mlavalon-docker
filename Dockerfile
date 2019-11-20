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
         && rm -rf /var/lib/apt/lists/* \
         && apt-get clean
RUN         ln -s /usr/bin/lsof /usr/sbin/ && \
            rm /etc/nginx/sites-enabled/default && \
            rm -f /etc/service/nginx/down && \
            ln -s /etc/nginx/sites-available/avalon /etc/nginx/sites-enabled/avalon && \
            chown app:docker_env /etc/container_environment.sh
ARG         AVALON_REPO=https://github.com/WGBH-MLA/mlavalon.git
ARG         AVALON_BRANCH=master
WORKDIR     /home/app

# no time for love, dr chowns
RUN         git clone --branch=${AVALON_BRANCH} --depth=1 ${AVALON_REPO} avalon
RUN         git reset --hard origin/master
RUN         git pull

RUN         chown -R app:app /home/app/avalon

USER        app
ADD         Gemfile.local /home/app/avalon/
ADD         config /home/app/avalon/config/
ARG         RAILS_ENV=production
RUN         cd avalon && \
            gem update --system && \
              gem install bundler && \
              bundle config build.nokogiri --use-system-libraries && \
              bundle install --path=vendor/gems --with postgres --without development test profiling mysql && \
              cd ..
ARG         BASE_URL
ARG         DATABASE_URL
RUN         cd avalon \
         && mkdir -p tmp/pids \
         && touch log/production.log \
         && ls -alh log \
         && bundle exec whenever -w -f config/docker_schedule.rb \
         && bundle exec rake assets:precompile SECRET_KEY_BASE=$(ruby -r 'securerandom' -e 'puts SecureRandom.hex(64)') \
         && cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml
USER        root
# RUN         chown -R app:app /home/app/avalon
ADD         ./avalon.conf /etc/nginx/sites-available/avalon
ADD         ./nginx_env.conf /etc/nginx/main.d/env.conf
ADD         rails_init.sh /etc/my_init.d/30_rails_init.sh
ADD         ./profile /etc/profile

# this needs to be in our rancher settings for the avalon workload so that it gets run on container start
# env | sed 's#^#export #1;s#=#&"#1;s#$#"&#1' > /etc/profile.d/avalon_nginx_env