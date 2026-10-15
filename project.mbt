///|
priv struct ProjectTarget {
  project_dir : String
  mode : @core.ProjectMode
}

///|
async fn validate_project_location(
  location : @core.ProjectLocation,
) -> ProjectTarget raise @core.CliError {
  let project_dir = absolute_path(location.path)
  let target : ProjectTarget = { project_dir, mode: location.mode, }
  match target.mode {
    Create => ensure_new_project_target(target.project_dir)
    Initialization => ensure_existing_dir(target.project_dir)
  }
  target
}

///|
async fn ensure_new_project_target(path : String) -> Unit raise @core.CliError {
  guard !path_exists(path) else {
    raise @core.cli_error(
      "path already exists: \{path}; use `momoka init` to initialize an existing directory",
    )
  }
}

///|
fn resolve_settings(
  overrides : @core.ProjectOverrides,
  preferred : PreferredConfig,
) -> @core.ProjectSettings {
  @core.ProjectSettings::new(
    @core.configured_value(
      overrides.license,
      preferred.license,
      @core.DEFAULT_LICENSE,
    ),
    @core.configured_value(overrides.host, preferred.host, @core.DEFAULT_HOST),
    @core.configured_value(
      overrides.preferred_target,
      preferred.preferred_target,
      @core.DEFAULT_TARGET,
    ),
  )
}

///|
async fn ProjectTarget::write_files(
  self : ProjectTarget,
  files : ArrayView[@core.ProjectFile],
) -> Unit raise @core.CliError {
  self.ensure_files_absent(files)
  for file in files {
    write_new_string_file(
      project_file_path(self.project_dir, file.filename),
      file.content,
    )
  }
}

///|
async fn ProjectTarget::ensure_files_absent(
  self : ProjectTarget,
  files : ArrayView[@core.ProjectFile],
) -> Unit raise @core.CliError {
  for file in files {
    let file_path = project_file_path(self.project_dir, file.filename)
    guard !path_exists(file_path) else {
      raise @core.cli_error("file already exists: \{file_path}")
    }
  }
}

///|
fn project_file_path(project_dir : String, filename : String) -> String {
  @path.Path::join(project_dir, filename).to_string()
}
