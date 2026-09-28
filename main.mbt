///|
async fn main {
  let args = match @env.args() {
    [_, .. args] => args
    [] => []
  }
  CliRequest::parse(args).execute()
}

///|
#cfg(target="native")
async fn CliRequest::execute(self : CliRequest) -> Unit raise @core.CliError {
  match self {
    Project(config) => config.execute()
    Upgrade(path) => run_upgrade_request(path)
    Stable => run_install_request(nightly=false)
    Nightly => run_install_request(nightly=true)
    Preferences(Configure) => configure_preferred_defaults()
    Preferences(Show) => show_preferred_defaults()
  }
}

///|
#cfg(target="wasm")
async fn CliRequest::execute(self : CliRequest) -> Unit raise @core.CliError {
  match self {
    Project(config) => config.execute()
  }
}

///|
async fn CliConfig::execute(self : CliConfig) -> Unit raise @core.CliError {
  let target = validate_project_location(self.location)
  let (username, settings) = resolve_project_options(self.overrides)
  match target.mode {
    Create => ensure_dir_recursive(target.project_dir)
    Initialization => ()
  }
  let files = @core.render_project_files(target.project_dir, username, settings)
  target.write_files(files)
  println(target.success_message(files))
}

///|
fn ProjectTarget::success_message(
  self : ProjectTarget,
  files : ArrayView[@core.ProjectFile],
) -> String {
  let action = match self.mode {
    Create => "created and initialized"
    Initialization => "initialized"
  }
  let file_names = files.map(f => f.filename).map(emph).join(", ")
  "\{action} \{file_names} in \{emph(self.project_dir)}"
}

///|
#cfg(target="native")
pub let emph : (String) -> String = s => @chalk.chalk().color(Cyan).render(s)

///|
#cfg(target="wasm")
pub let emph : (String) -> String = s => s
