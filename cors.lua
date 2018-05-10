local redis = require 'resty.redis'
local rc = require "resty.redis.connector"

local split = function(s, delimiter)
  result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
end


local EXPIRES = 10

local cors = {}

cors.set_header = function(host)
  local cache = ngx.shared["cors_domains"]

  local allowed_domain = cache:get(host)
  if allowed_domain ~= nil then
    ngx.header["Access-Control-Allow-Origin"] = allowed_domain
    return
  end

  local redis_password = ngx.var.redis_password
  local redis_hosts = split(ngx.var.redis_hosts, ",")
  local redis_master_name = ngx.var.redis_master_name

  local red, err = rc.new({
    master_name = redis_master_name,
    role = "master"
  }):connect{
    sentinels = {
        { host = redis_hosts[1], port = 26379 },
    }
  }

  if not red then
    ngx.log(ngx.ERR, "failed to connect to redis: ", err)
    ngx.header["Access-Control-Allow-Origin"] = host
    return
  end

  local allowed_domain = "globo.com" -- default domain

  local is_member, err = red:sismember("domains", host)
  if not is_member then
    ngx.log(ngx.ERR, "failed to check if " .. host.. "is allowed: ", err)
    ngx.header["Access-Control-Allow-Origin"] = host
    return
  end

  if is_member == 1 then -- checking whether host is member or not
    allowed_domain = host
  end

  cache:set(host, allowed_domain, EXPIRES)

  ngx.header["Access-Control-Allow-Origin"] = allowed_domain

  -- put it into the connection pool of size 100,
  -- with 10 seconds max idle time
  local ok, err = red:set_keepalive(10000, 100)
  if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
  end
end


return cors
