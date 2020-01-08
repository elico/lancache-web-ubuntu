FROM ubuntu:18.04 AS buildenv

# peek at: https://raw.githubusercontent.com/bntjah/lc-installer/master/installer.sh

## basic update and dev utils
RUN apt clean && apt update -y && \
	apt install curl git wget build-essential bash \
		libpcre3 zlib1g-dev libreadline-dev libncurses5-dev libssl-dev \
		httpry libudns0 libudns-dev libev4 libev-dev devscripts automake \
		libtool autoconf autotools-dev cdbs debhelper dh-autoreconf dpkg-dev \
		gettext pkg-config fakeroot libpcre3-dev libgd-dev libxpm-dev libgeoip-dev tcpdump -y && \
		apt clean

# Sources download and deployment 
RUN mkdir -p /build && \
	wget https://nginx.org/download/nginx-1.13.4.tar.gz -O /build/nginx-1.13.4.tar.gz && \
	cd /build && tar xf /build/nginx-1.13.4.tar.gz -C /build/ && \
	cd /build/nginx-1.13.4 && \
	wget http://labs.frickle.com/files/ngx_cache_purge-2.3.tar.gz -O /build/ngx_cache_purge-2.3.tar.gz && \
	tar xf /build/ngx_cache_purge-2.3.tar.gz -C /build/nginx-1.13.4/ && \
	git clone https://github.com/multiplay/nginx-range-cache/ /build/nginx-range-cache && \
	wget "https://codeload.github.com/wandenberg/nginx-push-stream-module/tar.gz/0.5.1?dummy=/wandenberg-nginx-push-stream-module-0.5.1_GH0.tar.gz" -O /build/wandenberg-nginx-push-stream-module-0.5.1_GH0.tar.gz && \
	tar xf /build/wandenberg-nginx-push-stream-module-0.5.1_GH0.tar.gz -C /build/nginx-1.13.4/ && \
	git clone -b master http://github.com/bntjah/lancache /build/lancache && \
	git clone https://github.com/dlundquist/sniproxy /build/sniproxy && \
	wget https://raw.githubusercontent.com/OpenSourceLAN/origin-docker/master/sniproxy/sniproxy.conf -O /build/etc-sniproxy.conf

## point For any update, upgrade or software addition

# Software building phase
## Nginx
RUN cd /build/nginx-1.13.4 && \
	patch -p1 </build/nginx-range-cache/range_filter.patch && \
	./configure --modules-path=/usr/local/nginx/modules \
		--add-module=/build/nginx-1.13.4/ngx_cache_purge-2.3 \
		--add-module=/build/nginx-range-cache \
		--add-module=/build/nginx-1.13.4/nginx-push-stream-module-0.5.1 \
		--with-cc-opt='-I /usr/local/include' \
		--with-ld-opt='-L /usr/local/lib' \
		--conf-path=/usr/local/nginx/nginx.conf \
		--sbin-path=/usr/local/sbin/nginx \
		--pid-path=/var/run/nginx.pid \
		--with-file-aio \
		--with-http_flv_module \
		--with-http_geoip_module=dynamic \
		--with-http_gzip_static_module \
		--with-http_image_filter_module=dynamic \
		--with-http_mp4_module \
		--with-http_realip_module \
		--with-http_slice_module \
		--with-http_stub_status_module \
		--with-pcre \
		--with-http_v2_module \
		--with-stream=dynamic \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-stream_realip_module \
		--with-http_ssl_module \
		--with-threads && \
		make -j8 && \
		make DESTDIR=/srv/fakeroot install

## Sniproxy
RUN cd /build/sniproxy && \
	./autogen.sh && \
	./configure && \
	make -j8  && \
	make DESTDIR=/srv/fakeroot install

## 
RUN tar cvfz /srv/lancache-nginx-latest.tar.gz -C /srv/fakeroot/ .


FROM ubuntu:18.04

RUN apt clean && apt update -y && \
	apt install -y git curl wget tcpdump libudns0 libpcre3 libtool gettext bash vim nginx nload iftop libev4 ruby && \
	apt purge -y nginx && \
	apt clean

COPY --from=buildenv /srv/lancache-nginx-latest.tar.gz /srv/lancache-nginx-latest.tar.gz

RUN mkdir -p /srv && tar xvf /srv/lancache-nginx-latest.tar.gz -C / 

COPY init-dirs.sh /srv/

## The data exists on the build node and shoud be up to date so no need to store the whole repository
# RUN git clone -b master http://github.com/bntjah/lancache /root/lancache

RUN adduser --system --no-create-home lancache && \
        addgroup --system lancache && \
        usermod -aG lancache lancache && \
        chmod +x /srv/init-dirs.sh && /srv/init-dirs.sh

COPY --from=buildenv /build/lancache/conf/ /usr/local/nginx/

COPY --from=buildenv /build/lancache/hosts /srv/etc/
COPY --from=buildenv /build/etc-sniproxy.conf /srv/etc/sniproxy.conf

COPY gen-vhosts-domains-conf.rb /srv/bin/gen-vhosts-domains-conf.rb
COPY init-hosts.sh /srv/bin/init-hosts.sh

COPY start.sh /srv/bin/start.sh

RUN chmod -v +x /srv/bin/*

EXPOSE 443
EXPOSE 80

COPY lancache-microsoft.domains-txt /srv/lancache-microsoft.domains-txt

VOLUME /srv

CMD [ "/srv/bin/start.sh" ]


