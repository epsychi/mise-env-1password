# mise-env-1password

A mise environment plugin that resolves 1Password CLI secret references into environment variables.

The `op` CLI must already be installed and authenticated.

## Install

Local path:

```toml
[plugins]
1password-env = { path = "/path/to/mise-env-1password" }
```

GitHub:

```toml
[plugins]
1password-env = "https://github.com/yourname/mise-env-1password"
```

## Usage

Create an env template containing `op://` references (default: `.env.op`):

```dotenv
DATABASE_URL=op://Vault/Database/password
API_TOKEN=op://Vault/Service/api-token
```

Configure the plugin in `mise.toml`:

```toml
[env]
_.1password-env = { env_file = ".env.op", tools = true }
```

## Options

- `env_file` (string): Env template file. Default: `.env.op`.
- `env_files` (array): Multiple env template files, in order. Later files override earlier ones.
- `vars` (table): Explicit key/value map. Values that start with `op://` are resolved with `op read`.
- `op_bin` (string): Path to the `op` binary. Default: `op`.
- `cache` (bool): Enable cacheable output for `env_cache`. Default: `true`.
- `require_env_file` (bool): Error when a configured env file is missing. Default: `false`.
- `tools` (bool): Include mise-managed tools on PATH for this hook. Default: `false`.

### Example with explicit vars

```toml
[env]
_.1password-env = {
  vars = {
    DATABASE_URL = "op://Vault/Database/password"
    STATIC_VALUE = "literal"
  }
}
```

### Example with multiple env files

```toml
[env]
_.1password-env = { env_files = [".env.op", ".env.local.op"] }
```

## Notes

- The plugin uses `op inject --in-file` to resolve env templates and `op read` for explicit vars.
- Secrets are resolved in memory and not written to disk by the plugin.
- For better performance, enable `env_cache` in your mise settings.

## License

MIT
