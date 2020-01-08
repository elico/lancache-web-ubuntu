#!/usr/bin/env bash

mkdir -p /srv/bin && \
mkdir -p /srv/etc && \
mkdir -p /srv/lancache/data/{microsoft,installs,other,tmp,hirez,origin,riot,gog,sony,steam,wargaming,arenanetworks,uplay,glyph,zenimax,digitalextremes,pearlabyss,blizzard,apple,epicgames} && \
mkdir -p /srv/lancache/logs/{Errors,Keys,Access} && \
chown -R lancache:lancache /srv/lancache && \
mkdir -p /usr/local/nginx/vhosts-domains/ && \
touch /usr/local/nginx/vhosts-domains/lancache-{microsoft,installs,other,tmp,hirez,origin,riot,gog,sony,steam,wargaming,arenanetworks,uplay,glyph,zenimax,digitalextremes,pearlabyss,blizzard,apple,epicgames}.conf
