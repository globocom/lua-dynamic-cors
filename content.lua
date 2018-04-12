local code = require 'code'
local domains = ngx.shared.domains
local url_user = ngx.var.host

if is_member(url_user) then
  domains:set("Access-Control-Allow-Origin", "*", 10)
else
  domains:set("Access-Control-Allow-Origin", "globo.com", 10)
end

local value, flags = domains:get("Access-Control-Allow-Origin")

ngx.header["Access-Control-Allow-Origin"] = value

ngx.say('Hello,world! ' .. url_user .. print_members())
