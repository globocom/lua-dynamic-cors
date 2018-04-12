FROM openresty/openresty:alpine-fat

RUN luarocks install luasocket
RUN luarocks install redis-lua
