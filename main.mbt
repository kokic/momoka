///|
async fn main {
  let args = match @env.args() {
    [_, .. args] => args
    [] => []
  }
  try run(args) catch {
    CliError(message) => {
      @stdio.stderr..write(message).write("\n")
      @sys.exit(1)
    }
  } noraise {
    message => println(message)
  }
}

///|
async fn run(args : ArrayView[String]) -> String raise CliError {
  match parse_cli_args(args) {
    Project(config) => run_project_request(config)
    Upgrade(path) => run_upgrade_request(path)
    Preferences(Configure) => configure_preferred_defaults()
    Preferences(Show) => show_preferred_defaults()
  }
}

///|
async fn run_project_request(config : CliConfig) -> String raise CliError {
  let target = validate_project_target(config.location)
  let user = ensure_username_with_preferred()
  match target.mode {
    Create => ensure_dir_recursive(target.project_dir)
    Initialization => ()
  }
  let settings = project_settings(config.overrides, user.preferred)
  let files = render_project_files(target.project_dir, user.username, settings)
  write_project_files(target.project_dir, files)
  target.mode.success_message(target.project_dir, files)
}

///|
fn ProjectMode::success_message(
  mode : ProjectMode,
  project_dir : String,
  files : ArrayView[ProjectFile],
) -> String {
  let action = match mode {
    Create => "created and initialized"
    Initialization => "initialized"
  }
  let file_names = files.map(f => f.filename).map(emph).join(", ")
  "\{action} \{file_names} in \{emph(project_dir)}"
}

///|
pub let emph : (String) -> String = s => @chalk.chalk().color(Cyan).render(s)
