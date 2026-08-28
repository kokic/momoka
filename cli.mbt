///|
/// Also see: moon.mod - `version`
pub const VERSION = "0.5.0"

///|
const DEFAULT_LICENSE : String = "AGPL-3.0"

///|
const DEFAULT_HOST : String = "github.com"

///|
const DEFAULT_TARGET : String = "native"

///|
const CLI_NAME : String = "momoka"

///|
const NEW_COMMAND : String = "new"

///|
const INIT_COMMAND : String = "init"

///|
const UPGRADE_COMMAND : String = "upgrade"

///|
const CFG_COMMAND : String = "cfg"

///|
priv struct ProjectLocation {
  path : String
  mode : ProjectMode
}

///|
priv struct ProjectOverrides {
  license : String?
  host : String?
  preferred_target : String?
}

///|
priv struct CliConfig {
  location : ProjectLocation
  overrides : ProjectOverrides
}

///|
priv enum ProjectMode {
  Create
  Init
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
fn project_options() -> Array[@argparse.OptionArg] {
  [
    @argparse.OptionArg(
      "license",
      short='l',
      about="License for moon.mod [default: prefs or \{DEFAULT_LICENSE}].",
    ),
    @argparse.OptionArg(
      "host",
      about="Repository hosting domain [default: prefs or \{DEFAULT_HOST}].",
    ),
    @argparse.OptionArg(
      "target",
      short='t',
      about="Preferred target [default: prefs or \{DEFAULT_TARGET}].",
    ),
  ]
}

///|
fn new_command() -> @argparse.Command {
  @argparse.Command(
    NEW_COMMAND,
    about="Create a new MoonBit module in a new directory.",
    options=project_options(),
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
fn init_command() -> @argparse.Command {
  @argparse.Command(
    INIT_COMMAND,
    about="Initialize a MoonBit module in an existing directory.",
    options=project_options(),
    positionals=[
      @argparse.PositionArg(
        "path",
        about="Project directory path [default: current directory].",
      ),
    ],
  )
}

///|
fn upgrade_command() -> @argparse.Command {
  @argparse.Command(
    UPGRADE_COMMAND,
    about="Upgrade all dependencies of the project to their latest versions.",
    positionals=[
      @argparse.PositionArg(
        "path",
        about="Project directory path [default: current directory].",
      ),
    ],
  )
}

///|
fn preferences_command() -> @argparse.Command {
  @argparse.Command(
    CFG_COMMAND,
    about="Configure default license / host / target, or print them.",
    flags=[
      @argparse.FlagArg("show", long="show", about="Print current preferences."),
    ],
  )
}

///|
fn cli_command() -> @argparse.Command {
  @argparse.Command(
    CLI_NAME,
    version=VERSION,
    about="Create a minimal MoonBit module.",
    subcommands=[
      new_command(),
      init_command(),
      upgrade_command(),
      preferences_command(),
    ],
    arg_required_else_help=true,
    subcommand_required=true,
  )
}

///|
fn matched_value(matches : @argparse.Matches, value_id : String) -> String? {
  matches.values.get(value_id).bind(values => values.last())
}

///|
fn project_overrides(matches : @argparse.Matches) -> ProjectOverrides {
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
    overrides: project_overrides(matches),
  })
}

///|
fn decode_init_request(matches : @argparse.Matches) -> CliRequest {
  Project({
    location: {
      path: matched_value(matches, "path").unwrap_or("."),
      mode: Init,
    },
    overrides: project_overrides(matches),
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
fn decode_subcommand(
  name : String,
  matches : @argparse.Matches,
) -> CliRequest raise CliError {
  match name {
    NEW_COMMAND => decode_new_request(matches)
    INIT_COMMAND => decode_init_request(matches)
    UPGRADE_COMMAND => Upgrade(matched_value(matches, "path").unwrap_or("."))
    CFG_COMMAND => decode_preferences_request(matches)
    _ => panic()
  }
}

///|
fn decode_cli_matches(matches : @argparse.Matches) -> CliRequest raise CliError {
  guard matches.subcommand is Some((name, submatches)) else { panic() }
  decode_subcommand(name, submatches)
}

///|
fn parse_cli_args(args : ArrayView[String]) -> CliRequest raise CliError {
  try @argparse.Command::parse(cli_command(), argv=args) catch {
    err => raise CliError("\{err}")
  } noraise {
    matches => decode_cli_matches(matches)
  }
}
