///|
/// Also see: moon.mod.json - `version`
pub const VERSION = "0.2.2"

///|
fn usage_text() -> String {
  (
    $|Momoka \{VERSION} - Create a minimal MoonBit module
    $|\{cli_command().render_help()}
    $|\{BANNER_TEXT}"
  )
}

///|
priv struct CliConfig {
  path : String
  license : String?
  repository_hosting : String?
  preferred_target : String?
  initialize_existing : Bool
}

///|
fn home_dir() -> String? {
  let home = @sys.get_env_var("HOME")
  if home is Some(path) && !path.is_empty() {
    Some(path)
  } else {
    let userprofile = @sys.get_env_var("USERPROFILE")
    if userprofile is Some(path) && !path.is_empty() {
      Some(path)
    } else {
      None
    }
  }
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
  @argparse.Command::new(
    "momoka",
    about="Create a minimal MoonBit module",
    version=VERSION,
    options=[
      @argparse.OptionArg::new(
        "license",
        short='l',
        long="license",
        about="License for moon.mod.json [default: prefs or AGPL-3.0].",
      ),
      @argparse.OptionArg::new(
        "host",
        long="host",
        about="Repository hosting domain [default: prefs or github.com].",
      ),
      @argparse.OptionArg::new(
        "target",
        short='t',
        long="target",
        about="Preferred target [default: prefs or native].",
      ),
    ],
    flags=[
      @argparse.FlagArg::new(
        "init",
        short='i',
        long="init",
        about="Initialize in an existing directory instead of creating it.",
      ),
    ],
    positionals=[
      @argparse.PositionArg::new(
        "path",
        about="Project directory path.",
        num_args=@argparse.ValueRange::new(lower=0, upper=1),
      ),
    ],
    subcommands=[
      preferences_command("prefs"),
      preferences_command("config", hidden=true),
    ],
    disable_help_subcommand=true,
  )
}

///|
fn matched_flag(matches : @argparse.Matches, flag_id : String) -> Bool {
  match matches.flags.get(flag_id) {
    Some(value) => value
    None => false
  }
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
  let initialize_existing = matched_flag(matches, "init")
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
  if matched_flag(matches, "show") {
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
        "prefs" | "config" => Ok(decode_preferences_request(submatches))
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

///|
const BANNER_TEXT : String =
  #|  __  __                       _         
  #| |  \/  | ___  _ __ ___   ___ | | ____ _ 
  #| | |\/| |/ _ \| '_ ` _ \ / _ \| |/ / _` |
  #| | |  | | (_) | | | | | | (_) |   < (_| |
  #| |_|  |_|\___/|_| |_| |_|\___/|_|\_\__,_|
  #|
