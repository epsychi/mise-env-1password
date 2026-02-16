# Basic example

This example validates that the plugin can load env vars from a `.env.op` file.

## Setup

From the repo root, link the plugin once:

```sh
mise plugins link 1password-env .
```

If mise prompts about trust, approve it with:

```sh
mise trust -y -C examples/basic
```

## Run

```sh
mise hook-env -s bash -C examples/basic
```

You should see exports for `HELLO`, `NUMBER`, and `ENABLED`.

To validate secret resolution, add a line like the following to `.env.op` using a real `op://` reference:

```dotenv
SECRET=op://Vault/Item/field
```
