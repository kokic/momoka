# Momoka

Create a minimal **Mo**onBit **mo**dule **か**? 

## Example

```sh
momoka new your-great-project

# or, cd <your-existing-project>
momoka init

# override project defaults for this invocation
momoka new your-great-project --username alice --license MIT --host gitlab.com --target js
momoka init --username alice

# upgrade all dependencies to their latest versions
momoka upgrade

# install the stable MoonBit toolchain
momoka stable

# select a local Git branch by number and check it out
momoka branch
```

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
  cfg      Configure default license / host / target, or print them.
  branch   Select and check out a local Git branch.
  help     Print help for the subcommand(s).

Options:
  -h, --help     Show help information.
  -V, --version  Show version information.
```

Use `momoka help <command>` (or `momoka <command> --help`) for subcommand
details. Both `new` and `init` support `--username` (`-u`), `--license` (`-l`),
`--host`, and `--target` (`-t`). These options override saved preferences for
the current invocation without changing them. License, host, and target fall
back to `AGPL-3.0`, `github.com`, and `native` when no preference is saved.
Without `--username` or a saved username, Momoka prompts for one and saves it
for future use. Use `momoka cfg` to configure default license, host, and target.
