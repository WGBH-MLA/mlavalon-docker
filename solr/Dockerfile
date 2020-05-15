FROM        solr:6.6.4-alpine
ARG         AVALON_BRANCH=master
COPY ./avalon_conf/ /home/solr/temp_avalon_conf/
WORKDIR /opt/solr
RUN mkdir avalon_conf
WORKDIR /home/solr
# overwrite conf files on the volume after container boot
CMD ['cp', '-rf'´, '/temp_avalon_conf/*', '/opt/solr/avalon_conf']
