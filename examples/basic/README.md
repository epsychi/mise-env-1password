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

You should see exports for `HELLO`, `NUMBER`, `ENABLED`, and `SECRET_PASSWORD`.

To validate secret resolution, add a line like the following to `.env.op` using a real `op://` reference:

```dotenv
SECRET_PASSWORD=op://Private/Test Item/password
```
