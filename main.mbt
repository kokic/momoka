///|
async fn main {
  let args = match @env.args() {
    [_, .. args] => args
    [] => []
  }
  match run(args) {
    Ok(message) => println(message)
    Err(err) => {
      @stdio.stderr..write(err).write("\n")
      @sys.exit(1)
    }
  }
}

///|
async fn run(args : ArrayView[String]) -> Result[String, String] {
  try run_or_raise(args) catch {
    CliError(message) => Err(message)
  } noraise {
    message => Ok(message)
  }
}

///|
async fn run_or_raise(args : ArrayView[String]) -> String raise CliError {
  handle_cli_request(parse_cli_args(args))
}

///|
async fn handle_cli_request(request : CliRequest) -> String raise CliError {
  match request {
    Help(topic) => help_text(topic)
    Project(config) => run_project_request(config)
    Preferences(Configure) => configure_preferred_defaults()
    Preferences(Show) => show_preferred_defaults()
  }
}

///|
async fn run_project_request(config : CliConfig) -> String raise CliError {
  let target = validate_project_target(config)
  let user = ensure_username_with_preferred()
  let project_dir = write_project_to_target(
    target,
    config,
    user.username,
    user.preferred,
  )
  project_success_message(config.mode, project_dir)
}

///|
fn project_success_message(mode : ProjectMode, project_dir : String) -> String {
  let action = project_action_text(mode)
  "\{action} moon.mod, moon.pkg and .gitignore in \{project_dir}"
}
