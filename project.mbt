///|
priv struct ProjectTarget {
  project_dir : String
  mode : ProjectMode
}

///|
priv struct ProjectSettings {
  license : String
  host : String
  preferred_target : String
}

///|
priv struct ProjectFiles {
  moon_mod : String
  moon_pkg : String
  gitignore : String
  gitattributes : String
}

///|
priv struct ProjectFile {
  filename : String
  content : String
}

///|
async fn validate_project_target(
  config : CliConfig,
) -> ProjectTarget raise CliError {
  let project_dir = absolute_path(config.location.path)
  let target : ProjectTarget = { project_dir, mode: config.location.mode }
  match target.mode {
    Create => ensure_new_project_target(target.project_dir)
    Init => ensure_existing_dir(target.project_dir)
  }
  target
}

///|
async fn ensure_new_project_target(path : String) -> Unit raise CliError {
  guard !path_exists(path) else {
    raise CliError(
      "path already exists: \{path}; use --init to initialize an existing directory",
    )
  }
}

///|
fn module_name_from_project_dir(project_dir : String) -> String {
  let module_name = @path.Path::basename(project_dir).to_owned()
  guard !module_name.is_empty() else { "moon-new-mini" }
  module_name
}

///|
async fn bootstrap_project(
  target : ProjectTarget,
  config : CliConfig,
  username : String,
  preferred : PreferredConfig,
) -> String raise CliError {
  match target.mode {
    Create => ensure_dir_recursive(target.project_dir)
    Init => ()
  }
  let files = render_project_files(
    target.project_dir,
    config.overrides,
    username,
    preferred,
  )
  write_project_files(target.project_dir, files)
  target.project_dir
}

///|
fn render_project_files(
  project_dir : String,
  overrides : ProjectOverrides,
  username : String,
  preferred : PreferredConfig,
) -> ProjectFiles {
  let settings = project_settings(overrides, preferred)
  let module_name = module_name_from_project_dir(project_dir)
  {
    moon_mod: moon_mod_content(
      username~,
      module_name~,
      settings.license,
      settings.host,
      settings.preferred_target,
    ),
    moon_pkg: moon_pkg_content(),
    gitignore: gitignore_content(),
    gitattributes: gitattributes_content(),
  }
}

///|
fn project_settings(
  overrides : ProjectOverrides,
  preferred : PreferredConfig,
) -> ProjectSettings {
  {
    license: configured_value(
      overrides.license,
      preferred.license,
      DEFAULT_LICENSE,
    ),
    host: configured_value(overrides.host, preferred.host, DEFAULT_HOST),
    preferred_target: configured_value(
      overrides.preferred_target,
      preferred.preferred_target,
      DEFAULT_TARGET,
    ),
  }
}

///|
fn configured_value(
  explicit : String?,
  preferred : String?,
  builtin : String,
) -> String {
  explicit.unwrap_or(preferred.unwrap_or(builtin))
}

///|
async fn write_project_files(
  project_dir : String,
  files : ProjectFiles,
) -> Unit raise CliError {
  let entries = files.to_entries()
  ensure_project_files_absent(project_dir, entries)
  for file in entries {
    write_new_string_file(
      project_file_path(project_dir, file.filename),
      file.content,
    )
  }
}

///|
async fn ensure_project_files_absent(
  project_dir : String,
  files : ArrayView[ProjectFile],
) -> Unit raise CliError {
  for file in files {
    let file_path = project_file_path(project_dir, file.filename)
    guard !path_exists(file_path) else {
      raise CliError("file already exists: \{file_path}")
    }
  }
}

///|
fn project_file_path(project_dir : String, filename : String) -> String {
  @path.Path::join(project_dir, filename).to_string()
}

///|
fn ProjectFiles::to_entries(self : ProjectFiles) -> Array[ProjectFile] {
  [
    { filename: "moon.mod", content: self.moon_mod },
    { filename: "moon.pkg", content: self.moon_pkg },
    { filename: ".gitignore", content: self.gitignore },
    { filename: ".gitattributes", content: self.gitattributes },
  ]
}
