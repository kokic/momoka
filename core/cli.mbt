///|
pub const DEFAULT_LICENSE : String = "Apache-2.0"

///|
pub const DEFAULT_HOST : String = "github.com"

///|
pub const DEFAULT_TARGET : String = "native"

///|
pub const VERSION : String = "0.7.0"

///|
pub enum ProjectMode {
  Create
  Initialization
}

///|
pub struct ProjectLocation {
  path : String
  mode : ProjectMode
}

///|
let about_newline_indent : String = " ".repeat(27)

///|
pub let project_options : Array[@argparse.OptionArg] = [
  @argparse.OptionArg(
    "username",
    short='u',
    about="MoonBit username for module name and repository.",
  ),
  @argparse.OptionArg(
    "license",
    short='l',
    about=(
      $|License for moon.mod [default: \{DEFAULT_LICENSE}]. 
      $|
      $|\{about_newline_indent}Example: Apache-2.0, GPL-3.0, MIT, BSD-3-Clause, CC0-1.0, EPL-2.0, AGPL-3.0, LGPL-3.0, MPL-2.0,  Unlicense, etc.
      $|
    ),
  ),
  @argparse.OptionArg(
    "host",
    about=(
      $|Repository hosting domain [default: \{DEFAULT_HOST}].
      $| 
      $|\{about_newline_indent}Example: github.com, gitlab.com, codeberg.org, sourcehut.org, tangled.org, etc.
      $|
    ),
  ),
  @argparse.OptionArg(
    "target",
    short='t',
    about=(
      $|Preferred target [default: \{DEFAULT_TARGET}]. 
      $|
      $|\{about_newline_indent}Example: wasm, wasm-gc, js, native.
      $|
    ),
  ),
]

///|
pub fn matched_value(matches : @argparse.Matches, value_id : String) -> String? {
  matches.values.get(value_id).bind(values => values.last())
}

///|
pub fn ProjectOverrides::from_matches(
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
pub fn decode_new_location(
  matches : @argparse.Matches,
) -> ProjectLocation raise CliError {
  guard matched_value(matches, "path") is Some(path) else {
    raise CliError("missing required argument: path")
  }
  { path, mode: Create, }
}

///|
pub fn decode_init_location(matches : @argparse.Matches) -> ProjectLocation {
  { path: matched_value(matches, "path").unwrap_or("."), mode: Initialization, }
}

///|
pub fn new_command() -> @argparse.Command {
  @argparse.Command(
    "new",
    about="Create a new MoonBit module in a new directory.",
    options=project_options,
    positionals=[
      @argparse.PositionArg(
        "path",
        about="Project directory path to create.",
        num_args=@argparse.ValueRange::single(),
      ),
    ],
  )
}

///|
pub fn init_command() -> @argparse.Command {
  @argparse.Command(
    "init",
    about="Initialize a MoonBit module in an existing directory.",
    options=project_options,
    positionals=[
      @argparse.PositionArg(
        "path",
        about="Project directory path [default: current directory].",
      ),
    ],
  )
}

///|
pub fn upgrade_command() -> @argparse.Command {
  @argparse.Command(
    "upgrade",
    about="Upgrade all dependencies of the project to their latest versions.",
    positionals=[
      @argparse.PositionArg(
        "path",
        about="Project directory path [default: current directory].",
      ),
    ],
  )
}
