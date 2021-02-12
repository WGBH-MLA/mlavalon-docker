FROM        solr:6.6.4-alpine
ARG         AVALON_BRANCH=master
COPY        ./avalon_conf/ /img_avalon_conf/
# always overwrite the schema on volume from the one we build into image (for updates)
CMD         cp /img_avalon_conf/* /opt/solr/avalon_conf   