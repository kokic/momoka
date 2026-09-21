///|
const DEFAULT_LICENSE : String = "AGPL-3.0"

///|
const DEFAULT_HOST : String = "github.com"

///|
const DEFAULT_TARGET : String = "native"

///|
priv struct ProjectLocation {
  path : String
  mode : ProjectMode
}

///|
priv struct CliConfig {
  location : ProjectLocation
  overrides : ProjectOverrides
}

///|
priv enum PreferencesRequest {
  Configure
  Show
}

///|
priv enum CliRequest {
  Project(CliConfig)
  Upgrade(String)
  Stable
  Nightly
  Branch
  Preferences(PreferencesRequest)
}

///|
let about_newline_indent : String = " ".repeat(27)

///|
let project_options : Array[@argparse.OptionArg] = [
  @argparse.OptionArg(
    "username",
    short='u',
    about="MoonBit username for module name and repository [default: prefs or prompt].",
  ),
  @argparse.OptionArg(
    "license",
    short='l',
    about=(
      $|License for moon.mod [default: prefs or \{DEFAULT_LICENSE}]. 
      $|
      $|\{about_newline_indent}Example: Apache-2.0, GPL-3.0, MIT, BSD-3-Clause, CC0-1.0, EPL-2.0, AGPL-3.0, LGPL-3.0, MPL-2.0,  Unlicense, etc.
      $|
    ),
  ),
  @argparse.OptionArg(
    "host",
    about=(
      $|Repository hosting domain [default: prefs or \{DEFAULT_HOST}].
      $| 
      $|\{about_newline_indent}Example: github.com, gitlab.com, codeberg.org, sourcehut.org, tangled.org, etc.
      $|
    ),
  ),
  @argparse.OptionArg(
    "target",
    short='t',
    about=(
      $|Preferred target [default: prefs or \{DEFAULT_TARGET}]. 
      $|
      $|\{about_newline_indent}Example: wasm, wasm-gc, js, native.
      $|
    ),
  ),
]

///|
fn matched_value(matches : @argparse.Matches, value_id : String) -> String? {
  matches.values.get(value_id).bind(values => values.last())
}

///|
fn ProjectOverrides::from_matches(
  matches : @argparse.Matches,
) -> ProjectOverrides {
  {
    username: matched_value(matches, "username"),
    license: matched_value(matches, "license"),
    host: matched_value(matches, "host"),
    preferred_target: matched_value(matches, "target"),
  }
}

///|
fn decode_new_request(matches : @argparse.Matches) -> CliRequest raise CliError {
  guard matched_value(matches, "path") is Some(path) else {
    raise CliError("missing required argument: path")
  }
  Project({
    location: { path, mode: Create, },
    overrides: ProjectOverrides::from_matches(matches),
  })
}

///|
fn decode_init_request(matches : @argparse.Matches) -> CliRequest {
  Project({
    location: {
      path: matched_value(matches, "path").unwrap_or("."),
      mode: Initialization,
    },
    overrides: ProjectOverrides::from_matches(matches),
  })
}

///|
fn decode_preferences_request(matches : @argparse.Matches) -> CliRequest {
  if matches.flags.get("show").unwrap_or(false) {
    Preferences(Show)
  } else {
    Preferences(Configure)
  }
}

///|
fn CliRequest::parse(args : ArrayView[String]) -> CliRequest raise CliError {
  let command = @argparse.Command(
    "momoka",
    version=VERSION,
    about="Create a minimal MoonBit module.",
    subcommands=[
      new_command(),
      init_command(),
      upgrade_command(),
      @argparse.Command("stable", about="Install the stable MoonBit toolchain."),
      @argparse.Command(
        "nightly",
        about="Install the nightly MoonBit toolchain.",
      ),
      preferences_command(),
      @argparse.Command(
        "branch",
        about="Select and check out a local Git branch.",
      ),
    ],
    arg_required_else_help=true,
    subcommand_required=true,
  )

  CliRequest::from_matches(
    @argparse.Command::parse(command, argv=args) catch {
      err => raise CliError("\{err}")
    },
  )
}

///|
fn CliRequest::from_matches(
  matches : @argparse.Matches,
) -> CliRequest raise CliError {
  guard! matches.subcommand is Some((name, submatches))
  match name {
    "new" => decode_new_request(submatches)
    "init" => decode_init_request(submatches)
    "upgrade" => Upgrade(matched_value(submatches, "path").unwrap_or("."))
    "stable" => Stable
    "nightly" => Nightly
    "cfg" => decode_preferences_request(submatches)
    "branch" => Branch
    _ => raise CliError("unknown command: \{name}")
  }
}
