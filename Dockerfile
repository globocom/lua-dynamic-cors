FROM openresty/openresty:alpine-fat

RUN luarocks install lua-resty-redis-connector
