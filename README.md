# fnox-plugin-template

A starting point for a [fnox](https://fnox.jdx.dev) provider written in Lua. Use it when fnox has no built-in provider for your secrets backend, such as an in-house API or a vendor CLI.

The template implements a working provider for an example REST API (`GET /v1/secrets/<ref>` returning `{"value": "..."}`) and tests it against a static mock. Replace the client with calls to your backend.

> [!NOTE]
> Lua provider plugins are new in fnox and not yet in a release ([jdx/fnox#968](https://github.com/jdx/fnox/pull/968)). Until they are, build fnox from that branch to use this template.

## Create your plugin

1. Click **Use this template** on GitHub, or run:

   ```sh
   gh repo create my-org/fnox-plugin-acme --template jdx/fnox-plugin-template --public --clone
   ```

2. Edit [`lib/client.lua`](lib/client.lua) to talk to your backend, and the hooks in [`provider.lua`](provider.lua) to match what it supports.
3. Update `test/fixtures` and `test/run.sh` to mock your backend, then run `mise run test`.

## Layout

| Path            | Purpose                                                                                         |
| --------------- | ----------------------------------------------------------------------------------------------- |
| `provider.lua`  | Entry point fnox loads. Returns the hook table: `get` (required), and optionally `get_batch`, `put`, `encrypt` and `test`. |
| `lib/`          | Plugin modules. fnox adds the plugin root and `lib/` to `package.path`, so `require("client")` loads `lib/client.lua`. |
| `test/`         | `run.sh` serves `fixtures/` with `python3 -m http.server` and runs `fnox` against it using `test/fnox.toml`. |

## Hooks

| Hook                   | Return value                                              | Used by                         |
| ---------------------- | --------------------------------------------------------- | ------------------------------- |
| `get(ctx, ref)`        | The secret value, or `nil` if it does not exist           | Every read                      |
| `get_batch(ctx, refs)` | A table mapping each found ref to its value               | Resolving several secrets       |
| `put(ctx, key, value)` | The reference to save in `fnox.toml`                      | `fnox set`                      |
| `encrypt(ctx, value)`  | Ciphertext to save in `fnox.toml`; `get` decrypts it      | `fnox set`, `fnox import`       |
| `test(ctx)`            | Nothing; raise an error on failure                        | `fnox provider test`            |

`ctx.options` holds the provider's `options` from `fnox.toml`. Raise `error(...)` for failures and `require("fnox").auth_error(...)` when credentials are missing or rejected, so fnox can offer the provider's `auth_command`. Plugins can also use `fnox.http`, `fnox.json`, `fnox.cmd`, `fnox.log` and `fnox.base64`. See the [Lua plugin docs](https://fnox.jdx.dev/providers/lua) for details.

## Develop

Link your checkout so fnox uses it directly, and point a provider at it:

```sh
fnox plugin link acme .
```

```toml
# fnox.toml in any project
[providers.acme]
type = "lua"
plugin = "acme"
options = { endpoint = "https://secrets.example.com", token_env = "ACME_TOKEN" }

[secrets]
DATABASE_URL = { provider = "acme", value = "database-url" }
```

```sh
fnox provider test acme
fnox get DATABASE_URL --verbose   # shows the plugin's log.debug output
```

Edits take effect on the next fnox command. Run `mise run test` for the bundled tests and `mise run fmt` to format with StyLua.

## Publish

Push the repository and tag releases. Users install a pinned version by declaring it in `fnox.toml`:

```toml
[plugins]
acme = "my-org/fnox-plugin-acme#v1.0.0"
```

fnox clones the plugin the first time a provider uses it. `fnox plugin update` moves it to the declared ref.

## License

MIT
