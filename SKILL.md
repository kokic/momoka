---
name: momoka
description: Create or initialize minimal MoonBit modules, upgrade module dependencies, manage defaults, or install the MoonBit toolchain with Momoka's native or wasm CLI.
---

# Momoka

Both the native and wasm CLI support all commands. Choose `new <path>` for a
directory that does not exist, or `init [path]` for an existing directory.
`init` defaults to the current directory.

Run the published `kokic/momoka` Registry package through `moonx`, which defaults
to the wasm target:

```sh
moonx kokic/momoka -- new my-project --username alice
moonx kokic/momoka -- init ./existing-project --username alice --license MIT --host gitlab.com --target js
```

Both commands generate `moon.mod`, `moon.pkg`, `.gitignore`, `.moonignore`, and
`.gitattributes`. They reject existing output files; do not delete those files
just to make initialization succeed. The module name uses the username and the
target directory's basename.

Options shared by `new` and `init`:

| Option | Meaning | Built-in default |
| --- | --- | --- |
| `--username`, `-u` | Module owner and repository username | Prompt if no saved value |
| `--license`, `-l` | Module license identifier | `Apache-2.0` |
| `--host` | Repository hosting domain | `github.com` |
| `--target`, `-t` | Generated module's preferred target | `native` |

Use the user's supplied values. Omitted options use saved preferences from
`~/.momoka/preferred.json`, then the built-in defaults above. If no username
is supplied or saved, Momoka prompts for one and saves it.

## Upgrade dependencies

Use `momoka upgrade [path...]` to upgrade all dependencies
of one or more existing MoonBit modules to their latest versions. Each
directory must contain `moon.mod`. Paths are processed in the supplied order;
omitting them defaults to `./`.

```sh
momoka upgrade
momoka upgrade ./mod-a ./mod-b
moonx kokic/momoka -- upgrade ./mod-a ./mod-b
```

## Preferences and toolchain

Use `momoka cfg` to configure saved defaults, or `momoka cfg --show` to print
them. Use `momoka stable` or `momoka nightly` to install the corresponding
MoonBit toolchain. These commands are also available through `moonx kokic/momoka`.

For local development, run `moon run --target wasm . -- <args>`. To run a
compiled artifact, use `moonrun <file.wasm> -- <args>`. The async library
requires MoonBit runtime host functions.
