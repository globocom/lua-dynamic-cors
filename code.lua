local redis = require 'redis'
local client = redis.connect('redis', 6379)
local response = client:ping()

-- populate the DB
client:sadd("url:list", "url:www.neymar.com", "url:globo.com", "url:http://www.globo.com/")

local members = client:smembers("url:list")

function is_member(url_user)
  for i, m in pairs(members) do
    ngx.log(ngx.ERR, m.." vs url:"..url_user)
    if m == "url:"..url_user then
      return true
    end
  end
  return false
end

function print_members()
  resp = ""
  if #members == 0 then
    resp = "\nnil"
  else
    resp = "\nnot nil\n"
    for i, m in pairs(members) do
      resp = resp .. "\n" .. m
    end
  end
  return resp
end
