---
name: momoka
description: Create or initialize MoonBit modules, upgrade their dependencies, bump module versions, configure defaults, or install MoonBit toolchains using Momoka through moonx.
---

# Momoka

| Command | Use |
| --- | --- |
| `moonx kokic/momoka -- new <path>` | Create a module in a new directory. |
| `moonx kokic/momoka -- init [path]` | Initialize an existing directory; defaults to `./`. |
| `moonx kokic/momoka -- upgrade [path...]` | Upgrade dependencies to their latest versions in one or more module directories; defaults to `./`. |
| `moonx kokic/momoka -- bump [path...]` | Increment the patch version in `moon.mod` for one or more module directories; defaults to `./`. |
| `moonx kokic/momoka -- cfg` | Configure saved defaults interactively. |
| `moonx kokic/momoka -- cfg --show` | Print saved defaults. |
| `moonx kokic/momoka -- stable` | Install the stable MoonBit toolchain. |
| `moonx kokic/momoka -- nightly` | Install the nightly MoonBit toolchain. |

`new` and `init` derive the module name from the username and directory basename. They reject existing output files; do not delete those files to force initialization. `upgrade` processes directories in the supplied order; each must contain `moon.mod`. `bump` reads `version = "x.y.z"` from `moon.mod` and increments `z`; it processes directories in the supplied order and leaves every other line unchanged.

## Module options

Pass these options to `new` or `init`:

| Option | Meaning | Built-in fallback |
| --- | --- | --- |
| `--username`, `-u` | Module owner and repository username | Prompt and save |
| `--license`, `-l` | Module license identifier | `Apache-2.0` |
| `--host` | Repository hosting domain | `github.com` |
| `--target`, `-t` | Generated module's preferred target | `native` |

Omitted options use saved preferences from `~/.momoka/preferred.json`, then
the built-in fallbacks above.

## SeekMoon sandbox

Commands such as `moonx kokic/momoka -- cfg` that write outside the module
directory are rejected. Pass equivalent options directly
to `new` or `init` instead of saving preferences. Explicitly supply `--username`
to avoid prompting for and saving a username to `~/.momoka/preferred.json`.

```sh
moonx kokic/momoka -- init ./mod --username alice --license MIT --host github.com --target native
```
