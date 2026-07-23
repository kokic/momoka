///|
/// Also see: moon.mod - `version`
pub const VERSION = "0.4.2"

///|
const DEFAULT_LICENSE : String = "AGPL-3.0"

///|
const DEFAULT_HOST : String = "github.com"

///|
const DEFAULT_TARGET : String = "native"

///|
const CLI_NAME : String = "momoka"

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
  Help(HelpTopic)
  Project(CliConfig)
  Preferences(PreferencesRequest)
}

///|
priv enum HelpTopic {
  TopLevelHelp
  PreferencesHelp
}

///|
priv struct NamedArgSpec {
  id : String
  short : Char?
  about : String
}

///|
priv struct PositionArgSpec {
  id : String
  about : String
}

///|
fn NamedArgSpec::to_option(self : NamedArgSpec) -> @argparse.OptionArg {
  @argparse.OptionArg(
    self.id,
    short?=self.short,
    long=self.id,
    about=self.about,
  )
}

///|
fn NamedArgSpec::to_flag(self : NamedArgSpec) -> @argparse.FlagArg {
  @argparse.FlagArg(self.id, short?=self.short, long=self.id, about=self.about)
}

///|
fn PositionArgSpec::to_positional(
  self : PositionArgSpec,
) -> @argparse.PositionArg {
  @argparse.PositionArg(
    self.id,
    about=self.about,
    num_args=@argparse.ValueRange(lower=0, upper=1),
  )
}

///|
fn preferences_command(
  name : String,
  hidden? : Bool = false,
) -> @argparse.Command {
  @argparse.Command(
    name,
    about="Configure default license / host / target, or print them.",
    flags=[
      @argparse.FlagArg("show", long="show", about="Print current preferences."),
    ],
    hidden~,
  )
}

///|
fn cli_command() -> @argparse.Command {
  let project_options = [
    {
      id: "license",
      short: Some('l'),
      about: "License for moon.mod [default: prefs or \{DEFAULT_LICENSE}].",
    },
    {
      id: "host",
      short: None,
      about: "Repository hosting domain [default: prefs or \{DEFAULT_HOST}].",
    },
    {
      id: "target",
      short: Some('t'),
      about: "Preferred target [default: prefs or \{DEFAULT_TARGET}].",
    },
  ]
  let project_flags = [
    {
      id: "init",
      short: Some('i'),
      about: "Initialize in an existing directory instead of creating it.",
    },
  ]
  let project_positionals = [{ id: "path", about: "Project directory path." }]
  @argparse.Command(
    CLI_NAME,
    version=VERSION,
    options=project_options.map(NamedArgSpec::to_option),
    flags=project_flags.map(NamedArgSpec::to_flag),
    positionals=project_positionals.map(PositionArgSpec::to_positional),
    subcommands=[preferences_command(CFG_COMMAND)],
    disable_help_subcommand=true,
  )
}

///|
fn matched_value(matches : @argparse.Matches, value_id : String) -> String? {
  matches.values.get(value_id).bind(values => values.last())
}

///|
fn decode_project_request(
  matches : @argparse.Matches,
) -> CliRequest raise CliError {
  let mode = if matches.flags.get("init").unwrap_or(false) {
    Init
  } else {
    Create
  }
  let path = match matched_value(matches, "path") {
    Some(path) => path
    None => if mode is Init { "." } else { raise CliError(usage_text()) }
  }
  Project({
    location: { path, mode },
    overrides: {
      license: matched_value(matches, "license"),
      host: matched_value(matches, "host"),
      preferred_target: matched_value(matches, "target"),
    },
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
  _name : String,
  submatches : @argparse.Matches,
) -> CliRequest {
  decode_preferences_request(submatches)
}

///|
fn decode_cli_matches(matches : @argparse.Matches) -> CliRequest raise CliError {
  match matches.subcommand {
    Some((name, submatches)) => decode_subcommand(name, submatches)
    None => decode_project_request(matches)
  }
}

///|
fn is_help_arg(arg : String) -> Bool {
  arg == "-h" || arg == "--help"
}

///|
fn help_request(args : ArrayView[String]) -> CliRequest? {
  match args {
    [] => Some(Help(TopLevelHelp))
    [arg] if is_help_arg(arg) => Some(Help(TopLevelHelp))
    ["cfg", arg] if is_help_arg(arg) => Some(Help(PreferencesHelp))
    _ => None
  }
}

///|
fn parse_cli_args(args : ArrayView[String]) -> CliRequest raise CliError {
  guard help_request(args) is Some(request) else {
    try @argparse.Command::parse(cli_command(), argv=args) catch {
      err => raise CliError("\{err}")
    } noraise {
      matches => decode_cli_matches(matches)
    }
  }
  request
}
