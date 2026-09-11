///|
async fn main {
  let args = match @env.args() {
    [_, .. args] => args
    [] => []
  }
  CliRequest::parse(args).execute() catch {
    CliError(message) => {
      @stdio.stderr..write(message).write("\n")
      @sys.exit(1)
    }
  }
}

///|
async fn CliRequest::execute(self : CliRequest) -> Unit raise CliError {
  match self {
    Project(config) => config.execute()
    Upgrade(path) => run_upgrade_request(path)
    Stable => run_install_request(process=install_stable)
    Nightly => run_install_request(process=install_nightly)
    Preferences(Configure) => configure_preferred_defaults()
    Preferences(Show) => show_preferred_defaults()
  }
}

///|
async fn CliConfig::execute(self : CliConfig) -> Unit raise CliError {
  let target = self.location.validate()
  let user = ensure_username_with_preferred()
  match target.mode {
    Create => ensure_dir_recursive(target.project_dir)
    Initialization => ()
  }
  let settings = self.overrides.resolve(user.preferred)
  let files = target.render_files(user.username, settings)
  target.write_files(files)
  println(target.success_message(files))
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
