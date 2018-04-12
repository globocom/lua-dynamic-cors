docker run --rm -p 8081:8081 -v $(pwd)/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf -v $(pwd):/lua/ openresty/openresty:alpine
