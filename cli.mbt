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
fn usage_text() -> String {
  let momoka = @chalk.chalk().color(YellowBright).render("Momoka")
  let version = @chalk.chalk().modifier(Bold).render("\{VERSION}")
  let description = @chalk.chalk()
    .modifier(Bold)
    .render("Create a minimal MoonBit module")
  let intro = "\{momoka} \{version} - \{description}"
  (
    $|\{intro}
    $|\{cli_command().render_help()}
    $|\{BANNER_TEXT}
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
  initialize_existing : Bool
}

///|
priv enum PreferencesRequest {
  Configure
  Show
}

///|
priv enum CliRequest {
  Help
  Project(CliConfig)
  Preferences(PreferencesRequest)
}

///|
fn cli_arg_parts(spec : ArrayView[String]) -> (String, String, String) {
  match spec {
    [id, short, about] => (id, short, about)
    _ => abort("invalid CLI arg spec")
  }
}

///|
fn cli_short(short : String) -> Char? {
  if short.is_empty() {
    None
  } else {
    guard short.char_length() == 1 else { abort("invalid CLI short arg spec") }
    short.get_char(0)
  }
}

///|
fn option_arg(spec : ArrayView[String]) -> @argparse.OptionArg {
  let (id, short, about) = cli_arg_parts(spec)
  @argparse.OptionArg(id, short?=cli_short(short), long=id, about~)
}

///|
fn flag_arg(spec : ArrayView[String]) -> @argparse.FlagArg {
  let (id, short, about) = cli_arg_parts(spec)
  @argparse.FlagArg(id, short?=cli_short(short), long=id, about~)
}

///|
fn optional_position_arg(spec : ArrayView[String]) -> @argparse.PositionArg {
  let (id, short, about) = cli_arg_parts(spec)
  guard short.is_empty() else {
    abort("positional CLI arg spec cannot have short arg")
  }
  @argparse.PositionArg(
    id,
    about~,
    num_args=@argparse.ValueRange(lower=0, upper=1),
  )
}

///|
fn[T] map_specs(
  specs : ArrayView[Array[String]],
  mapper : (ArrayView[String]) -> T,
) -> Array[T] {
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
fn cli_command() -> @argparse.Command {
  let project_options = [
    [
      "license",
      "l",
      "License for moon.mod [default: prefs or \{DEFAULT_LICENSE}].",
    ],
    [
      "host",
      "",
      "Repository hosting domain [default: prefs or \{DEFAULT_HOST}].",
    ],
    ["target", "t", "Preferred target [default: prefs or \{DEFAULT_TARGET}]."],
  ]
  let project_flags = [
    ["init", "i", "Initialize in an existing directory instead of creating it."],
  ]
  let project_positionals = [["path", "", "Project directory path."]]
  @argparse.Command(
    "momoka",
    version=VERSION,
    options=map_specs(project_options, option_arg),
    flags=map_specs(project_flags, flag_arg),
    positionals=map_specs(project_positionals, optional_position_arg),
    subcommands=[preferences_command("cfg")],
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
) -> Result[CliRequest, String] {
  let initialize_existing = matches.flags.get("init").unwrap_or(false)
  let path = match matched_value(matches, "path") {
    Some(path) => path
    None => if initialize_existing { "." } else { return Err(usage_text()) }
  }
  Ok(
    Project({
      path,
      license: matched_value(matches, "license"),
      repository_hosting: matched_value(matches, "host"),
      preferred_target: matched_value(matches, "target"),
      initialize_existing,
    }),
  )
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
) -> Result[CliRequest, String] {
  if name == "cfg" {
    Ok(decode_preferences_request(submatches))
  } else {
    Err("unsupported CLI subcommand: \{name}")
  }
}

///|
fn decode_cli_matches(
  matches : @argparse.Matches,
) -> Result[CliRequest, String] {
  match matches.subcommand {
    Some((name, submatches)) => decode_subcommand(name, submatches)
    None => decode_project_request(matches)
  }
}

///|
fn has_help_flag(args : ArrayView[String]) -> Bool {
  for arg in args {
    if arg == "-h" || arg == "--help" {
      return true
    }
  }
  false
}

///|
fn parse_cli_args(args : ArrayView[String]) -> Result[CliRequest, String] {
  guard args.length() != 0 else { return Ok(Help) }
  guard !has_help_flag(args) else { return Ok(Help) }
  try @argparse.Command::parse(cli_command(), argv=args) catch {
    err => Err("\{err}")
  } noraise {
    matches => decode_cli_matches(matches)
  }
}
