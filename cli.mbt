/// Also see: moon.mod.json - `version`
const VERSION = "0.2.0"

///|
fn usage_text() -> String {
  (
    $| Momoka \{VERSION} - Create a minimal MoonBit module
    #|
    #|Usage:
    #|  momoka [OPTIONS] <PATH>
    #|  momoka --init [OPTIONS] [PATH]
    #|  momoka prefs [--show]
    #|
    #|Commands:
    #|  prefs  Configure default license / host / target, or print with --show [aliases: config]
    #|
    #|Arguments:
    #|  <PATH>  Project directory path
    #|
    #|Options:
    #|  -l, --license <LICENSE>  License for moon.mod.json [default: prefs or AGPL-3.0]
    #|      --host <HOST>        Repository hosting domain [default: prefs or github.com]
    #|  -t, --target <TARGET>    Preferred target [default: prefs or native]
    #|  -i, --init               Initialize in an existing directory instead of creating it
    #|      --show               Print current preferences for prefs / config command
    #|  -h, --help               Print help
    $|\{BANNER_TEXT}
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
fn parse_cli_args(args : ArrayView[String]) -> Result[CliConfig, String] {
  if args.length() == 0 {
    return Err(usage_text())
  }
  let mut path : String? = None
  let mut license : String? = None
  let mut repository_hosting : String? = None
  let mut preferred_target : String? = None
  let mut initialize_existing = false
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if arg == "--help" || arg == "-h" {
      return Err(usage_text())
    } else if arg == "--license" || arg == "-l" {
      guard i + 1 < args.length() else {
        return Err("missing value for \{arg}\n\{usage_text()}")
      }
      license = Some(args[i + 1])
      i = i + 2
    } else if arg == "--host" {
      guard i + 1 < args.length() else {
        return Err("missing value for \{arg}\n\{usage_text()}")
      }
      repository_hosting = Some(args[i + 1])
      i = i + 2
    } else if arg == "--target" || arg == "-t" {
      guard i + 1 < args.length() else {
        return Err("missing value for \{arg}\n\{usage_text()}")
      }
      preferred_target = Some(args[i + 1])
      i = i + 2
    } else if arg == "--init" || arg == "-i" {
      initialize_existing = true
      i = i + 1
    } else if arg.has_prefix("-") {
      return Err("unknown option: \{arg}\n\{usage_text()}")
    } else if path is None {
      path = Some(arg)
      i = i + 1
    } else {
      return Err("unexpected positional argument: \{arg}\n\{usage_text()}")
    }
  }
  let resolved_path = match path {
    Some(path) => path
    None =>
      if initialize_existing {
        "."
      } else {
        return Err(usage_text())
      }
  }
  Ok(
    {
      path: resolved_path,
      license,
      repository_hosting,
      preferred_target,
      initialize_existing,
    },
  )
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
fn is_preferences_command(arg : String) -> Bool {
  arg == "prefs" || arg == "config"
}

///|
fn is_preferences_show_option(arg : String) -> Bool {
  arg == "--show"
}

///|
async fn run(args : ArrayView[String]) -> Result[String, String] {
  if args.length() > 0 && is_preferences_command(args[0]) {
    if args.length() == 1 {
      return configure_preferred_defaults()
    }
    if args.length() == 2 && is_preferences_show_option(args[1]) {
      return show_preferred_defaults()
    }
    if args.length() > 1 && args[1] == "--help" {
      return Err(usage_text())
    }
    return Err("unexpected arguments for \{args[0]}\n\{usage_text()}")
  }
  match parse_cli_args(args) {
    Ok(config) =>
      match ensure_username() {
        Ok(username) => {
          let preferred = match home_dir() {
            Some(home) => load_preferred_config(preferred_file_path(home))
            None => empty_preferred_config()
          }
          let result = if config.initialize_existing {
            init_project(config, username, preferred)
          } else {
            create_project(config, username, preferred)
          }
          match result {
            Ok(project_dir) =>
              {
                let action = if config.initialize_existing {
                  "initialized"
                } else {
                  "created and initialized"
                }
                Ok(
                  "\{action} moon.mod.json, moon.pkg and .gitignore in \{project_dir}",
                )
              }
            Err(err) => Err(err)
          }
        }
        Err(err) => Err(err)
      }
    Err(err) => Err(err)
  }
}

///|
pub async fn export_main() -> Unit {
  match @env.args() {
    [_, .. args] =>
      match run(args) {
        Ok(message) => println(message)
        Err(err) => {
          println(err)
          @sys.exit(1)
        }
      }
    [] => {
      println(usage_text())
      @sys.exit(1)
    }
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
