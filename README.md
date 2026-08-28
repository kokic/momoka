# Momoka

Create a minimal **Mo**onBit **mo**dule **か**? 

## Example

```sh
momoka new your-great-project

# or, cd <your-existing-project>
momoka init

# upgrade all dependencies to their latest versions
momoka upgrade
```

## Help

```sh
Usage: momoka <command>

Create a minimal MoonBit module.

Commands:
  new      Create a new MoonBit module in a new directory.
  init     Initialize a MoonBit module in an existing directory.
  upgrade  Upgrade all dependencies of the project to their latest versions.
  cfg      Configure default license / host / target, or print them.
  help     Print help for the subcommand(s).

Options:
  -h, --help     Show help information.
  -V, --version  Show version information.
```

Use `momoka help <command>` (or `momoka <command> --help`) for subcommand
details. For example, `momoka new --help` shows the `--license`, `--host`,
and `--target` options used to override the defaults stored via `momoka cfg`.
