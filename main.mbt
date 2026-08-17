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
  handle_cli_request(parse_cli_args(args))
}

///|
async fn handle_cli_request(request : CliRequest) -> String raise CliError {
  match request {
    Help(topic) => topic.text()
    Project(config) => run_project_request(config)
    Upgrade(path) => run_upgrade_request(path)
    Preferences(Configure) => configure_preferred_defaults()
    Preferences(Show) => show_preferred_defaults()
  }
}

///|
async fn run_project_request(config : CliConfig) -> String raise CliError {
  let target = validate_project_target(config)
  let user = ensure_username_with_preferred()
  let (project_dir, files) = bootstrap_project(
    target,
    config,
    user.username,
    user.preferred,
  )
  config.location.mode.success_message(project_dir, files)
}

///|
fn ProjectMode::success_message(
  self : ProjectMode,
  project_dir : String,
  files : ArrayView[ProjectFile],
) -> String {
  let action = self.action_text()
  let file_names = files.map(fn(f) { f.filename }).map(emph).join(", ")
  "\{action} \{file_names} in \{emph(project_dir)}"
}

///|
pub let emph : (String) -> String = s => @chalk.chalk().color(Cyan).render(s)
