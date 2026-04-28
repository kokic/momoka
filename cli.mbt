///|
/// Also see: moon.mod.json - `version`
pub const VERSION = "0.2.3"

///|
fn usage_text() -> String {
  (
    $|Momoka \{VERSION} - Create a minimal MoonBit module
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
  @argparse.OptionArg::new(id, short?=cli_short(short), long=id, about~)
}

///|
fn flag_arg(spec : ArrayView[String]) -> @argparse.FlagArg {
  let (id, short, about) = cli_arg_parts(spec)
  @argparse.FlagArg::new(id, short?=cli_short(short), long=id, about~)
}

///|
fn optional_position_arg(spec : ArrayView[String]) -> @argparse.PositionArg {
  let (id, short, about) = cli_arg_parts(spec)
  guard short.is_empty() else {
    abort("positional CLI arg spec cannot have short arg")
  }
  @argparse.PositionArg::new(
    id,
    about~,
    num_args=@argparse.ValueRange::new(lower=0, upper=1),
  )
}

///|
fn option_args(specs : ArrayView[Array[String]]) -> Array[@argparse.OptionArg] {
  let args = []
  for spec in specs {
    args.push(option_arg(spec))
  }
  args
}

///|
fn flag_args(specs : ArrayView[Array[String]]) -> Array[@argparse.FlagArg] {
  let args = []
  for spec in specs {
    args.push(flag_arg(spec))
  }
  args
}

///|
fn optional_position_args(
  specs : ArrayView[Array[String]],
) -> Array[@argparse.PositionArg] {
  let args = []
  for spec in specs {
    args.push(optional_position_arg(spec))
  }
  args
}

///|
fn preferences_command(
  name : String,
  hidden? : Bool = false,
) -> @argparse.Command {
  @argparse.Command::new(
    name,
    about="Configure default license / host / target, or print them.",
    flags=[
      @argparse.FlagArg::new(
        "show",
        long="show",
        about="Print current preferences.",
      ),
    ],
    hidden~,
  )
}

///|
fn cli_command() -> @argparse.Command {
  let project_options = [
    ["license", "l", "License for moon.mod.json [default: prefs or AGPL-3.0]."],
    ["host", "", "Repository hosting domain [default: prefs or github.com]."],
    ["target", "t", "Preferred target [default: prefs or native]."],
  ]
  let project_flags = [
    ["init", "i", "Initialize in an existing directory instead of creating it."],
  ]
  let project_positionals = [["path", "", "Project directory path."]]
  @argparse.Command::new(
    "momoka",
    about="Create a minimal MoonBit module",
    version=VERSION,
    options=option_args(project_options),
    flags=flag_args(project_flags),
    positionals=optional_position_args(project_positionals),
    subcommands=[preferences_command("cfg")],
    disable_help_subcommand=true,
  )
}

///|
fn matched_value(matches : @argparse.Matches, value_id : String) -> String? {
  match matches.values.get(value_id) {
    Some(values) if values.length() > 0 => Some(values[values.length() - 1])
    _ => None
  }
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
fn decode_cli_matches(
  matches : @argparse.Matches,
) -> Result[CliRequest, String] {
  match matches.subcommand {
    Some((name, submatches)) =>
      match name {
        "cfg" => Ok(decode_preferences_request(submatches))
        _ => abort("unsupported CLI subcommand")
      }
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
  if args.length() == 0 {
    return Err(usage_text())
  }
  if has_help_flag(args) {
    return Err(usage_text())
  }
  try @argparse.Command::parse(cli_command(), argv=args) catch {
    err => Err("\{err}")
  } noraise {
    matches => decode_cli_matches(matches)
  }
}
