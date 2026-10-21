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
| `moonx kokic/momoka -- evol [path...]` | Upgrade and check modules as one repository; any dependency change bumps all selected modules, and all checks must pass before one commit. Add `--orphan` for independent repositories, or `--pr` to push a branch, open a draft PR, and return to `main`. Defaults to `./`. |
| `moonx kokic/momoka -- pin [path...]` | Run `git add .`, commit `chore: snapshot update`, and `git push` for one or more module directories; defaults to `./`. |
| `moonx kokic/momoka -- cfg` | Configure saved defaults interactively. |
| `moonx kokic/momoka -- cfg --show` | Print saved defaults. |
| `moonx kokic/momoka -- stable` | Install the stable MoonBit toolchain. |
| `moonx kokic/momoka -- nightly` | Install the nightly MoonBit toolchain. |

`new` and `init` derive the module name from the username and directory basename. They reject existing output files; do not delete those files to force initialization. `upgrade`, `bump`, and `evol` process directories in the supplied order. When a directory has no `moon.mod`, they read its `moon.work` and process every `members` entry as a module instead. `bump` reads `version = "x.y.z"` from `moon.mod` and increments `z`; it processes directories in the supplied order and leaves every other line unchanged. `evol` treats selected modules as one repository: any dependency change bumps all selected modules, then all must pass `moon check` before a single commit at the repository root. `--orphan` treats each module as a separate repository, bumps only when its own dependencies changed, continues after failures, and exits with an error if any module failed. Successful checks forward their output. `evol` stages all changes and commits `chore: update dependencies and bump module patch versions`. With `--pr`, it commits only when dependencies changed: it creates and checks out `update-dependencies` before bumping, then pushes that branch and opens a draft pull request with the same title. After successful PR creation it checks out `main`. `pin` stages all changes, creates a `chore: snapshot update` commit, and pushes.

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
