///|
priv struct ProjectTarget {
  project_dir : String
  mode : ProjectMode
}

///|
priv struct ProjectSettings {
  license : String
  repository_hosting : String
  preferred_target : String
}

///|
priv struct ProjectFiles {
  moon_mod : String
  moon_pkg : String
  gitignore : String
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
  let project_dir = absolute_path(config.path)
  let target : ProjectTarget = { project_dir, mode: config.mode }
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
async fn ensure_existing_dir(path : String) -> Unit raise CliError {
  guard path_exists(path) else {
    raise CliError("directory does not exist: \{path}")
  }
  try @fs.kind(path) catch {
    err =>
      raise CliError(
        "failed to inspect directory \{path}: \{@debug.to_repr(err)}",
      )
  } noraise {
    Directory => ()
    _ => raise CliError("path exists but is not a directory: \{path}")
  }
}

///|
async fn write_project_to_target(
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
    config,
    username,
    preferred,
  )
  write_project_files(target.project_dir, files)
  target.project_dir
}

///|
fn render_project_files(
  project_dir : String,
  config : CliConfig,
  username : String,
  preferred : PreferredConfig,
) -> ProjectFiles {
  let settings = project_settings(config, preferred)
  let module_name = module_name_from_project_dir(project_dir)
  {
    moon_mod: file_content_moon_mod(
      username~,
      module_name~,
      settings.license,
      settings.repository_hosting,
      settings.preferred_target,
    ),
    moon_pkg: file_content_moon_pkg(),
    gitignore: file_content_gitignore(),
  }
}

///|
fn project_settings(
  config : CliConfig,
  preferred : PreferredConfig,
) -> ProjectSettings {
  {
    license: configured_value(
      config.license,
      preferred.license,
      DEFAULT_LICENSE,
    ),
    repository_hosting: configured_value(
      config.repository_hosting,
      preferred.repository_hosting,
      DEFAULT_HOST,
    ),
    preferred_target: configured_value(
      config.preferred_target,
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
  Option::unwrap_or(explicit, Option::unwrap_or(preferred, builtin))
}

///|
async fn write_project_files(
  project_dir : String,
  files : ProjectFiles,
) -> Unit raise CliError {
  let entries = project_file_entries(files)
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
fn project_file_entries(files : ProjectFiles) -> Array[ProjectFile] {
  [
    { filename: "moon.mod", content: files.moon_mod },
    { filename: "moon.pkg", content: files.moon_pkg },
    { filename: ".gitignore", content: files.gitignore },
  ]
}
