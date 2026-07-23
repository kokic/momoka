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
fn usage_text() -> String {
  let momoka = @chalk.chalk().color(YellowBright).render("Momoka")
  
  let version = @chalk.chalk().modifier(Bold).render("\{VERSION}")
  
  let description = @chalk.chalk()
    .modifier(Bold)
    .render("Create a minimal MoonBit module")
  
  let banner = @chalk.chalk()
    .color(YellowBright)
    .modifier(Bold)
    .render(BANNER_TEXT)

  let intro = "\{momoka} \{version} - \{description}"
  (
    $|\{intro}
    $|\{cli_command().render_help()}
    $|\{banner}
  )
}

///|
const BANNER_TEXT : String =
  #|  __  __                       _         
  #| |  \/  | ___  _ __ ___   ___ | | ____ _ 
  #| | |\/| |/ _ \| '_ ` _ \ / _ \| |/ / _` |
  #| | |  | | (_) | | | | | | (_) |   < (_| |
  #| |_|  |_|\___/|_| |_| |_|\___/|_|\_\__,_|
  #|

///|
priv struct CliConfig {
  path : String
  license : String?
  repository_hosting : String?
  preferred_target : String?
  mode : ProjectMode
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
fn option_arg(spec : NamedArgSpec) -> @argparse.OptionArg {
  @argparse.OptionArg(
    spec.id,
    short?=spec.short,
    long=spec.id,
    about=spec.about,
  )
}

///|
fn flag_arg(spec : NamedArgSpec) -> @argparse.FlagArg {
  @argparse.FlagArg(spec.id, short?=spec.short, long=spec.id, about=spec.about)
}

///|
fn optional_position_arg(spec : PositionArgSpec) -> @argparse.PositionArg {
  @argparse.PositionArg(
    spec.id,
    about=spec.about,
    num_args=@argparse.ValueRange(lower=0, upper=1),
  )
}

///|
fn[T, U] map_specs(specs : ArrayView[T], mapper : (T) -> U) -> Array[U] {
  specs.map(spec => mapper(spec))
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
fn preferences_help_text() -> String {
  preferences_command("\{CLI_NAME} \{CFG_COMMAND}").render_help()
}

///|
fn help_text(topic : HelpTopic) -> String {
  match topic {
    TopLevelHelp => usage_text()
    PreferencesHelp => preferences_help_text()
  }
}

///|
fn project_action_text(mode : ProjectMode) -> String {
  match mode {
    Create => "created and initialized"
    Init => "initialized"
  }
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
    options=map_specs(project_options, option_arg),
    flags=map_specs(project_flags, flag_arg),
    positionals=map_specs(project_positionals, optional_position_arg),
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
    path,
    license: matched_value(matches, "license"),
    repository_hosting: matched_value(matches, "host"),
    preferred_target: matched_value(matches, "target"),
    mode,
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
  submatches : @argparse.Matches,
) -> CliRequest raise CliError {
  if name == CFG_COMMAND {
    decode_preferences_request(submatches)
  } else {
    raise CliError("unsupported CLI subcommand: \{name}")
  }
}

///|
fn decode_cli_matches(matches : @argparse.Matches) -> CliRequest raise CliError {
  match matches.subcommand {
    Some((name, submatches)) => decode_subcommand(name, submatches)
    None => decode_project_request(matches)
  }
}

///|
fn is_top_level_help_request(args : ArrayView[String]) -> Bool {
  args.length() == 1 && is_help_arg(args[0])
}

///|
fn is_help_arg(arg : String) -> Bool {
  arg == "-h" || arg == "--help"
}

///|
fn help_request(args : ArrayView[String]) -> CliRequest? {
  guard args.length() != 0 else { Some(Help(TopLevelHelp)) }
  guard !is_top_level_help_request(args) else { Some(Help(TopLevelHelp)) }
  guard !(args.length() == 2 && args[0] == CFG_COMMAND && is_help_arg(args[1])) else {
    Some(Help(PreferencesHelp))
  }
  None
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
