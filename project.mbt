///|
priv struct ProjectOverrides {
  license : String?
  host : String?
  preferred_target : String?
}

///|
priv enum ProjectMode {
  Create
  Initialization
}

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
priv struct ProjectFile {
  filename : String
  content : String
}

///|
async fn validate_project_target(
  location : ProjectLocation,
) -> ProjectTarget raise CliError {
  let project_dir = absolute_path(location.path)
  let target : ProjectTarget = { project_dir, mode: location.mode, }
  match target.mode {
    Create => ensure_new_project_target(target.project_dir)
    Initialization => ensure_existing_dir(target.project_dir)
  }
  target
}

///|
async fn ensure_new_project_target(path : String) -> Unit raise CliError {
  guard !path_exists(path) else {
    raise CliError(
      "path already exists: \{path}; use `momoka init` to initialize an existing directory",
    )
  }
}

///|
fn module_name_from_project_dir(project_dir : String) -> String raise CliError {
  let module_name = @path.Path::basename(project_dir).to_owned()
  guard !module_name.is_empty() else {
    raise CliError("cannot derive a module name from directory: \{project_dir}")
  }
  module_name
}

///|
fn render_project_files(
  project_dir : String,
  username : String,
  settings : ProjectSettings,
) -> Array[ProjectFile] raise CliError {
  let module_name = module_name_from_project_dir(project_dir)
  [
    {
      filename: "moon.mod",
      content: moon_mod_content(
        username~,
        module_name~,
        settings.license,
        settings.host,
        settings.preferred_target,
      ),
    },
    { filename: "moon.pkg", content: moon_pkg_content(), },
    { filename: ".gitignore", content: gitignore_content(), },
    { filename: ".gitattributes", content: gitattributes_content(), },
  ]
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
  files : ArrayView[ProjectFile],
) -> Unit raise CliError {
  ensure_project_files_absent(project_dir, files)
  for file in files {
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
