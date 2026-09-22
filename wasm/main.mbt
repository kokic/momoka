///|
async fn main {
  let args = match @env.args() {
    [_, .. args] => args
    [] => []
  }
  CliRequest::parse(args).execute()
}

///|
async fn CliRequest::execute(self : CliRequest) -> Unit raise @core.CliError {
  match self {
    Project(config) => config.execute()
  }
}

///|
async fn CliConfig::execute(self : CliConfig) -> Unit raise @core.CliError {
  let target = validate_project_location(self.location)
  let username = ensure_username(self.overrides.username)
  match target.mode {
    Create => ensure_dir_recursive(target.project_dir)
    Initialization => ()
  }
  let settings = resolve_settings(self.overrides)
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
  let file_names = files.map(f => f.filename).join(", ")
  "\{action} \{file_names} in \{self.project_dir}"
}
