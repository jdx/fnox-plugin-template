-- Example HTTP client for a REST secrets API. Replace it with calls to your
-- backend; plugins can also run CLIs with `require("fnox.cmd")`.
--
-- The example API serves `GET <endpoint>/v1/secrets/<ref>` and returns
-- `{"value": "..."}`, authenticated with a bearer token read from the
-- environment variable named by the `token_env` option.

local fnox = require("fnox")
local http = require("fnox.http")
local json = require("fnox.json")
local log = require("fnox.log")

local M = {}

local function endpoint(ctx)
  local url = ctx.options.endpoint
  if url == nil or url == "" then
    error("set `options.endpoint` on provider '" .. ctx.provider .. "'")
  end
  return (url:gsub("/+$", ""))
end

local function headers(ctx)
  local token_env = ctx.options.token_env or "EXAMPLE_TOKEN"
  local token = os.getenv(token_env)
  if token == nil or token == "" then
    -- auth_error lets fnox offer the provider's `auth_command`
    fnox.auth_error(token_env .. " is not set")
  end
  return {
    Accept = "application/json",
    Authorization = "Bearer " .. token,
  }
end

local function check(resp, what)
  if resp.status == 401 or resp.status == 403 then
    fnox.auth_error(what .. " was rejected (HTTP " .. resp.status .. ")")
  end
  if not resp.ok then
    error(what .. " failed with HTTP " .. resp.status)
  end
end

--- Read one secret; nil when the API reports it does not exist.
function M.read(ctx, ref)
  local url = endpoint(ctx) .. "/v1/secrets/" .. ref
  log.debug("GET", url)
  local resp = http.get(url, { headers = headers(ctx) })
  if resp.status == 404 then
    return nil
  end
  check(resp, "reading '" .. ref .. "'")
  local body = json.decode(resp.body)
  if type(body) ~= "table" or type(body.value) ~= "string" then
    error("unexpected response for '" .. ref .. '\': expected {"value": string}')
  end
  return body.value
end

--- Fail if the API is unreachable or the token is not accepted.
function M.ping(ctx)
  local resp = http.get(endpoint(ctx) .. "/v1/health", { headers = headers(ctx) })
  check(resp, "health check")
end

return M
