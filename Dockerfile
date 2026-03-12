# Asterisk for Kubernetes
#
# It is expected that the configuration should be generated separately, as from https://github.com/CyCoreSystems/asterisk-config.
#

FROM debian:stretch as builder
MAINTAINER Seán C McCord "ulexus@gmail.com"

ENV ASTERISK_VER 17.3.0

# Update stretch repositories
RUN sed -i -e 's/deb.debian.org/archive.debian.org/g' \
           -e 's|security.debian.org|archive.debian.org/|g' \
           -e '/stretch-updates/d' /etc/apt/sources.list

# Install Asterisk
RUN apt-get update && \
   apt-get install -y autoconf build-essential libcurl3 libjansson-dev libxml2-dev libncurses5-dev libspeex-dev libcurl4-openssl-dev libedit-dev libspeexdsp-dev libgsm1-dev libsrtp0-dev uuid-dev sqlite3 libsqlite3-dev libspandsp-dev pkg-config python-dev libssl-dev openssl libopus-dev liburiparser-dev xmlstarlet curl wget git && \
   apt-get clean && \
   rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /tmp
RUN curl -o /tmp/asterisk.tar.gz http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VER}.tar.gz && \
   tar xf /tmp/asterisk.tar.gz && \
   cd /tmp/asterisk-${ASTERISK_VER}

RUN curl -L -o /tmp/audiofork.tar.gz https://github.com/nadirhamid/asterisk-audiofork/archive/refs/tags/v0.0.1.tar.gz &&\
   cd /tmp/asterisk-${ASTERISK_VER} &&\
   tar xf /tmp/audiofork.tar.gz &&\
   cp asterisk-audiofork-0.0.1/app_audiofork.c apps/

# RUN curl -L -o /tmp/audiosocket.tar.gz https://github.com/CyCoreSystems/audiosocket/archive/master.tar.gz &&\
#    cd /tmp/asterisk-${ASTERISK_VER} &&\
#    tar xf /tmp/audiosocket.tar.gz &&\
#    cp audiosocket-master/asterisk/apps/* apps/ &&\
#    cp audiosocket-master/asterisk/channels/* channels/ &&\
#    cp -R audiosocket-master/asterisk/include/* include/ &&\
#    cp audiosocket-master/asterisk/res/* res/

RUN cd /tmp/asterisk-${ASTERISK_VER} &&\
   ./configure --with-pjproject-bundled --with-jansson-bundled --with-spandsp --with-opus && \
   make menuselect.makeopts && \
   menuselect/menuselect --disable CORE-SOUNDS-EN-GSM --enable CORE-SOUNDS-EN-ULAW --enable codec_opus --disable BUILD_NATIVE menuselect.makeopts && \
   make && \
   make install && \
   rm -Rf /tmp/*

FROM debian:stretch
COPY --from=builder /usr/sbin/asterisk /usr/sbin/
COPY --from=builder /usr/sbin/safe_asterisk /usr/sbin/
COPY --from=builder /usr/lib/libasterisk* /usr/lib/
COPY --from=builder /usr/lib/asterisk/ /usr/lib/asterisk
COPY --from=builder /var/lib/asterisk/ /var/lib/asterisk
COPY --from=builder /var/spool/asterisk/ /var/spool/asterisk

# Update stretch repositories
RUN sed -i -e 's/deb.debian.org/archive.debian.org/g' \
           -e 's|security.debian.org|archive.debian.org/|g' \
           -e '/stretch-updates/d' /etc/apt/sources.list

# Add required runtime libs
RUN apt-get update && \
   apt-get install -y gnupg libjansson4 xml2 libncurses5 libspeex1 libcurl4-openssl-dev libedit2 libspeexdsp1 libgsm1 libsrtp0 uuid libsqlite3-0 libspandsp2 libssl1.1 libopus0 liburiparser1 xmlstarlet curl wget gettext-base && \
   apt-get clean && \
   rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add sngrep
COPY irontec.list /etc/apt/sources.list.d/irontec.list
RUN curl -L http://packages.irontec.com/public.key | apt-key add -
RUN apt-get update && \
   apt-get install -y sngrep && \
   rm -Rf /var/lib/apt/lists/ /tmp/* /var/tmp/*

RUN curl -qL -o /usr/bin/netdiscover https://github.com/CyCoreSystems/netdiscover/releases/download/v1.2.3/netdiscover.linux.amd64
RUN chmod +x /usr/bin/netdiscover


# Copy configs
COPY ./configs/* /etc/asterisk/

# Add entrypoint script
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ADD scripts/cleanup_asterisk_logs.sh /usr/local/bin/cleanup_asterisk_logs.sh
RUN chmod +x /usr/local/bin/cleanup_asterisk_logs.sh

# install cron
# todo: consolidate this with the first command we use to install APT packages. look into why this doesn't work and fix.
RUN apt update -y && apt install -y cron && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/cron.d

# 3. Create the crontab file
RUN echo "0 3 * * * /usr/local/bin/cleanup_asterisk_logs.sh" > /etc/cron.d/log-cleanup

# 4. Give execution rights to the cron job
RUN chmod 0644 /etc/cron.d/log-cleanup


# 5. Apply the cron job
RUN crontab /etc/cron.d/log-cleanup

WORKDIR /
ENTRYPOINT ["/entrypoint.sh"]
CMD []
