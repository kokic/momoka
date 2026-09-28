# Momoka

Create a minimal **Mo**onBit **mo**dule **か**? 

Momoka is a single MoonBit module, `kokic/momoka`, with two packages:

| Directory | Package             | Target           | Purpose                    |
| --------- | ------------------- | ---------------- | -------------------------- |
| `.`       | `kokic/momoka`      | `native`, `wasm` | shared CLI                 |
| `core`    | `kokic/momoka/core` | any              | shared pure logic, no I/O  |

`core` holds the shared templates, settings resolution, and CLI definitions. The
CLI shares argument parsing and project creation across both targets. Native
builds read and save preferences in `~/.momoka/preferred.json`; wasm builds use
only command-line arguments and built-in defaults. Conditional compilation
excludes preference file access and native-only commands from wasm builds.

```sh
moon run --target native . -- --help
moon run --target wasm . -- --help
```

## Example

```sh
# native: preferences are read from and saved to ~/.momoka/preferred.json
momoka new your-great-project

# or, cd <your-existing-project>
momoka init

# override project defaults for this invocation
momoka new your-great-project --username alice --license MIT --host gitlab.com --target js
momoka init --username alice

# configure or print the saved defaults
momoka cfg
momoka cfg --show

# upgrade all dependencies to their latest versions
momoka upgrade

# install the stable MoonBit toolchain
momoka stable

# select a local Git branch by number and check it out
momoka branch
```

## WASM

The `wasm` build supports `new` and `init` only. It never reads or writes
`~/.momoka`; pass everything on the command line. `--username` falls back to
`guest` when omitted.

```sh
moon run --target wasm . -- new your-great-project --username alice --license MIT
```

Run wasm builds with MoonBit's runtime (`moon run` / `moonrun`); the async
library requires MoonBit host functions beyond standard WASI.

## Help

```sh
Usage: momoka <command>

Create a minimal MoonBit module.

Commands:
  new      Create a new MoonBit module in a new directory.
  init     Initialize a MoonBit module in an existing directory.
  upgrade  Upgrade all dependencies of the project to their latest versions.
  stable   Install the stable MoonBit toolchain.
  nightly  Install the nightly MoonBit toolchain.
  cfg      Configure default username / license / host / target, or print them.
  branch   Select and check out a local Git branch.
  help     Print help for the subcommand(s).

Options:
  -h, --help     Show help information.
  -V, --version  Show version information.
```

The command list above is for native builds. Use `momoka help <command>` (or
`momoka <command> --help`) for subcommand
details. Both `new` and `init` support `--username` (`-u`), `--license` (`-l`),
`--host`, and `--target` (`-t`). These options override the saved preferences for
the current invocation without changing them. License, host, and target fall
back to `Apache-2.0`, `github.com`, and `native`. Without `--username` or a saved
username, Momoka prompts for one and saves it for future use. Use `momoka cfg`
to configure default username, license, host, and target; press Enter to keep an
existing value. Use `momoka cfg --show` to display all saved preferences.
