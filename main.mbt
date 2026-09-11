///|
async fn main {
  let args = match @env.args() {
    [_, .. args] => args
    [] => []
  }
  try CliRequest::parse(args).execute() catch {
    CliError(message) => {
      @stdio.stderr..write(message).write("\n")
      @sys.exit(1)
    }
  } noraise {
    message => println(message)
  }
}

///|
async fn CliRequest::execute(self : CliRequest) -> String raise CliError {
  match self {
    Project(config) => config.execute()
    Upgrade(path) => run_upgrade_request(path)
    Preferences(Configure) => configure_preferred_defaults()
    Preferences(Show) => show_preferred_defaults()
  }
}

///|
async fn CliConfig::execute(self : CliConfig) -> String raise CliError {
  let target = self.location.validate()
  let user = ensure_username_with_preferred()
  match target.mode {
    Create => ensure_dir_recursive(target.project_dir)
    Initialization => ()
  }
  let settings = self.overrides.resolve(user.preferred)
  let files = target.render_files(user.username, settings)
  target.write_files(files)
  target.success_message(files)
}

///|
fn ProjectTarget::success_message(
  self : ProjectTarget,
  files : ArrayView[ProjectFile],
) -> String {
  let action = match self.mode {
    Create => "created and initialized"
    Initialization => "initialized"
  }
  let file_names = files.map(f => f.filename).map(emph).join(", ")
  "\{action} \{file_names} in \{emph(self.project_dir)}"
}

///|
pub let emph : (String) -> String = s => @chalk.chalk().color(Cyan).render(s)
