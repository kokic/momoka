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
  Preferences(PreferencesRequest)
}

///|
let about_newline_indent : String = " ".repeat(27)

///|
let project_options : Array[@argparse.OptionArg] = [
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
fn Subcommand::decode(
  self : Subcommand,
  matches : @argparse.Matches,
) -> CliRequest raise CliError {
  match self {
    Create => decode_new_request(matches)
    Initialization => decode_init_request(matches)
    Upgrade => Upgrade(matched_value(matches, "path").unwrap_or("."))
    Config => decode_preferences_request(matches)
  }
}

///|
fn CliRequest::parse(args : ArrayView[String]) -> CliRequest raise CliError {
  let command = @argparse.Command(
    "momoka",
    version=VERSION,
    about="Create a minimal MoonBit module.",
    subcommands=Subcommand::all().map(command => command.command()),
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
  guard! Subcommand::from_name(name) is Some(command)
  command.decode(submatches)
}
