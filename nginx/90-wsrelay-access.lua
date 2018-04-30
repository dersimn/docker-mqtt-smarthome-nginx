local HMAC_SECRET = "hunter2"
local crypto = require "crypto"

function ComputeHmac(msg, expires)
  return crypto.hmac.digest("sha256", string.format("%s%d", msg, expires), HMAC_SECRET)
end

verify_status = ngx.var.ssl_client_verify

if verify_status == "SUCCESS" then
  client = crypto.digest("sha256", ngx.var.ssl_client_cert)
  expires = ngx.time() + 3600

  ngx.header["Set-Cookie"] = {
    string.format("AccessToken=%s; path=/", ComputeHmac(client, expires)),
    string.format("ClientId=%s; path=/", client),
    string.format("AccessExpires=%d; path=/", expires)
  }
  return
elseif verify_status == "NONE" then
  client = ngx.var.cookie_ClientId
  client_hmac = ngx.var.cookie_AccessToken
  access_expires = ngx.var.cookie_AccessExpires

  if client ~= nil and client_hmac ~= nil and access_expires ~= nil then
    hmac = ComputeHmac(client, access_expires)

    if hmac ~= "" and hmac == client_hmac and tonumber(access_expires) > ngx.time() then
      return
    end
  end
end

ngx.exit(ngx.HTTP_FORBIDDEN)
