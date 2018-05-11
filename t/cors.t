use Test::Nginx::Socket 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();
our $ServRoot = "/tmp/srvroot";


our $HttpConfig = qq{
  lua_package_path "/lua-modules/resty/?.lua;/lua/?.lua;;";
  lua_shared_dict cors_domains 1m;
};

no_long_string();
run_tests();


__DATA__

=== TEST 1: set globo.com when domain not allowed
--- http_config eval: $::HttpConfig
--- config
location /t {
    set $redis_hosts "172.100.0.10";
    set $redis_port 26379;
    set $redis_password "";
    set $redis_master_name "mymaster";

    content_by_lua_block {
      local cors = require 'cors'

      cors.init({
        dict_name = "cors_domains",
        redis = {
          master_name = ngx.var.redis_master_name,
          password = ngx.var.redis_password,
          hosts =  ngx.var.redis_hosts,
          port = ngx.var.redis_port
        },
        default_domain = "globo.com"
      })

      cors.set_header("example.com")
    }
}
--- request
GET /t

--- response_headers
Access-Control-Allow-Origin: globo.com

--- no_error_log
[error]



=== TEST 2: set given domain if redis failed
--- http_config eval: $::HttpConfig
--- config
location /t {
    set $redis_hosts "bla";
    set $redis_master_name "mymaster";
    set $redis_port 26379;

    content_by_lua_block {
      local cors = require 'cors'

      cors.init({
        dict_name = "cors_domains",
        redis = {
          master_name = ngx.var.redis_master_name,
          password = ngx.var.redis_password,
          hosts =  ngx.var.redis_hosts,
          port = ngx.var.redis_port
        },
        default_domain = "globo.com"
      })

      cors.set_header("example.com")
    }
}
--- request
GET /t

--- response_headers
Access-Control-Allow-Origin: example.com

--- error_log
failed to connect to redis



=== TEST 3: set given domain if allowed
--- http_config eval: $::HttpConfig
--- config
location /t {
    set $redis_hosts "172.100.0.10";
    set $redis_port 26379;
    set $redis_master_name "mymaster";

    content_by_lua_block {
      local rc = require("resty.redis.connector")
      local red, err = rc.new({}):connect{
        sentinels = {
            { host = ngx.var.redis_hosts, port = 26379 },
        }
      }

      ok , err = red:sadd("cors_domains", "neymar.com")
      assert(ok ~= nil)

      local cors = require 'cors'

      cors.init({
        dict_name = "cors_domains",
        redis = {
          master_name = ngx.var.redis_master_name,
          password = ngx.var.redis_password,
          hosts =  ngx.var.redis_hosts,
          port = ngx.var.redis_port
        },
        default_domain = "globo.com"
      })

      cors.set_header("neymar.com")
    }
}
--- request
GET /t

--- response_headers
Access-Control-Allow-Origin: neymar.com

--- no_error_log
[error]
