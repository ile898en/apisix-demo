FROM ubuntu:18.04

RUN apt-get update && apt-get -y install jq && apt-get -y install curl

COPY apisix_init/start.sh /start.sh
COPY apisix_init/log /usr/local/apisix/init/log

COPY apisix_init/upstream/upstream.json /usr/local/apisix/upstream/
COPY apisix_init/routes/routes.json /usr/local/apisix/routes/

COPY apisix_init/cert /usr/local/apisix/cert/

ENTRYPOINT ["bash", "/start.sh"]