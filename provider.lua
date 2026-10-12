-- fnox provider plugin entry point.
--
-- fnox loads this file and calls the hooks in the table it returns. Every hook
-- receives `ctx` first:
--   ctx.provider    the provider name from fnox.toml
--   ctx.options     the provider's `options` table (string values)
--   ctx.plugin_dir  this plugin's directory
--
-- Docs: https://fnox.jdx.dev/providers/lua

local client = require("client")

return {
  -- Required. `ref` is the secret's `value` from fnox.toml.
  -- Return the secret value, or nil if it does not exist.
  get = function(ctx, ref)
    return client.read(ctx, ref)
  end,

  -- Optional. Raise an error when the backend is unreachable or misconfigured.
  -- Used by `fnox provider test`.
  test = function(ctx)
    client.ping(ctx)
  end,

  -- Optional. Resolve many secrets in one call. `refs` is a list of unique
  -- references; return a table mapping each found ref to its value. Without
  -- this hook, fnox calls `get` for each secret, up to 10 at a time.
  --
  -- get_batch = function(ctx, refs)
  --   local values = {}
  --   for _, ref in ipairs(refs) do
  --     values[ref] = client.read(ctx, ref)
  --   end
  --   return values
  -- end,

  -- Optional. Store a value remotely for `fnox set`, and return the reference
  -- to save in fnox.toml (defaults to `key` if you return nil).
  --
  -- put = function(ctx, key, value)
  --   client.write(ctx, key, value)
  --   return key
  -- end,

  -- Optional. For encryption plugins: return ciphertext to store in fnox.toml.
  -- `get` then receives the ciphertext as `ref` and must decrypt it.
  --
  -- encrypt = function(ctx, value)
  --   return ...
  -- end,
}
