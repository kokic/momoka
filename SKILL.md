---
name: momoka
description: Create or initialize minimal MoonBit modules with Momoka's stateless wasm CLI, using command-line options without reading or writing saved preferences.
---

# Momoka

Use the wasm CLI to generate a minimal MoonBit module. Choose `new <path>` for a
directory that does not exist, or `init [path]` for an existing directory.
`init` defaults to the current directory.

Run the `kokic/momoka` Registry package through `moonx`:

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
| `--username`, `-u` | Module owner and repository username | `guest` |
| `--license`, `-l` | Module license identifier | `Apache-2.0` |
| `--host` | Repository hosting domain | `github.com` |
| `--target`, `-t` | Generated module's preferred target | `native` |

Use the user's supplied values; omitted options use the defaults above.
