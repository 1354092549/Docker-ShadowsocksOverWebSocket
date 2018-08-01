FROM node:alpine
USER root
RUN npm config set unsafe-perm true\
 && npm install -g ws-translater

RUN set -ex \
 && apk add --no-cache --virtual .build-deps git autoconf automake build-base c-ares-dev libev-dev libtool libsodium-dev linux-headers mbedtls-dev pcre-dev \
 && git clone https://github.com/shadowsocks/shadowsocks-libev.git\
 && cd shadowsocks-libev \
 && git submodule init && git submodule update\
 && ./autogen.sh \
 && ./configure --prefix=/usr --disable-documentation \
 && make install \
 && apk del .build-deps \
 && apk add --no-cache rng-tools $(scanelf --needed --nobanner /usr/bin/ss-* | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | sort -u) \
 && cd .. \
 && rm -rf shadowsocks-libev

EXPOSE 8333
ENV PASSWORD google520
ENV METHOD aes-256-cfb
ENV TIMEOUT 300
ENV DNS_ADDRS 8.8.8.8,8.8.4.4
ENV ARGS=
RUN mkdir -p /opt/bin \
 && echo "#!/bin/sh" > /opt/bin/entrypoint.sh \
 && echo "wst ToWS 127.0.0.1 8388 8333 &" >> /opt/bin/entrypoint.sh \
 && echo "ss-server -s 0.0.0.0 -p 8388 -k ${PASSWORD} -m ${METHOD} -t ${TIMEOUT} --fast-open -d ${DNS_ADDRS} ${ARGS}" >> /opt/bin/entrypoint.sh \
 && chmod +x /opt/bin/entrypoint.sh

USER nobody
ENTRYPOINT ["/opt/bin/entrypoint.sh"]