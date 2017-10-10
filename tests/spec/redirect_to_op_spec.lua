local http = require("socket.http")
local url = require("socket.url")
require 'busted.runner'()

-- must double percents for Lua regexes
local function urlescape_for_regex(s)
  return string.gsub(url.escape(s), "%%", "%%%%")
end

describe("when accessing the protected resource without token", function()
  local _, status, headers = http.request({
    url = "http://localhost/default/t",
    redirect = false
  })
  it("redirects to the authorization endpoint", function()
    assert.are.equals(302, status)
    assert.truthy(string.match(headers["location"], "http://localhost/authorize%?.*client_id=client_id.*"))
  end)
  it("requests the authorization code grant flow", function()
    assert.truthy(string.match(headers["location"], ".*response_type=code.*"))
  end)
  it("uses the configured redirect uri", function()
    local redir_escaped = urlescape_for_regex("http://localhost/redirect_uri")
    -- lower as url.escape uses %2f for a slash, openidc uses %2F
    assert.truthy(string.match(string.lower(headers["location"]),
                               ".*redirect_uri=" .. string.lower(redir_escaped) .. ".*"))
  end)
  it("uses a state parameter", function()
    assert.truthy(string.match(headers["location"], ".*state=.*"))
  end)
  it("uses a nonce parameter", function()
    assert.truthy(string.match(headers["location"], ".*nonce=.*"))
  end)
  it("uses the default scopes", function()
    assert.truthy(string.match(headers["location"],
                               ".*scope=" .. urlescape_for_regex("openid email profile") .. ".*"))
  end)
  it("doesn't use the prompt parameter", function()
    assert.falsy(string.match(headers["location"], ".*prompt=.*"))
  end)
end)

describe("when accessing the custom protected resource without token", function()
  local _, status, headers = http.request({
    url = "http://localhost/custom/t",
    redirect = false
  })
  it("uses the configured scope", function()
    assert.truthy(string.match(headers["location"], ".*scope=my%-scope.*"))
  end)
end)
