///|
async fn create_project(
  config : CliConfig,
  username : String,
  preferred : PreferredConfig,
) -> Result[String, String] {
  let project_dir = match absolute_path(config.path) {
    Ok(path) => path
    Err(err) => return Err(err)
  }
  match path_exists(project_dir) {
    Ok(true) =>
      return Err(
        "path already exists: \{project_dir}; use --init to initialize an existing directory",
      )
    Ok(false) => ()
    Err(err) => return Err(err)
  }
  write_project_after_check(
    project_dir,
    ensure_dir_recursive(project_dir),
    config,
    username,
    preferred,
  )
}

///|
async fn init_project(
  config : CliConfig,
  username : String,
  preferred : PreferredConfig,
) -> Result[String, String] {
  let project_dir = match absolute_path(config.path) {
    Ok(path) => path
    Err(err) => return Err(err)
  }
  write_project_after_check(
    project_dir,
    ensure_existing_dir(project_dir),
    config,
    username,
    preferred,
  )
}

///|
async fn write_project_after_check(
  project_dir : String,
  check_result : Result[Unit, String],
  config : CliConfig,
  username : String,
  preferred : PreferredConfig,
) -> Result[String, String] {
  match check_result {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  let result = write_project_files(project_dir, config, username, preferred)
  result.map(_ => project_dir)
}

///|
async fn ensure_existing_dir(path : String) -> Result[Unit, String] {
  match path_exists(path) {
    Ok(true) => ()
    Ok(false) => return Err("directory does not exist: \{path}")
    Err(err) => return Err(err)
  }

  try @fs.kind(path) catch {
    err => Err("failed to inspect directory \{path}: \{@debug.to_repr(err)}")
  } noraise {
    Directory => Ok(())
    _ => Err("path exists but is not a directory: \{path}")
  }
}

///|
async fn write_project_files(
  project_dir : String,
  config : CliConfig,
  username : String,
  preferred : PreferredConfig,
) -> Result[Unit, String] {
  let module_name = module_name_from_project_dir(project_dir)
  let license = Option::unwrap_or(
    config.license,
    Option::unwrap_or(preferred.license, DEFAULT_LICENSE),
  )
  let repository_hosting = Option::unwrap_or(
    config.repository_hosting,
    Option::unwrap_or(preferred.repository_hosting, DEFAULT_HOST),
  )
  let preferred_target = Option::unwrap_or(
    config.preferred_target,
    Option::unwrap_or(preferred.preferred_target, DEFAULT_TARGET),
  )
  let moon_mod_content = file_content_moon_mod(
    username~,
    module_name~,
    license,
    repository_hosting,
    preferred_target,
  )
  let moon_mod_path = @path.Path::join(project_dir, "moon.mod").to_string()
  match write_string_file(moon_mod_path, moon_mod_content) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }

  let moon_pkg_content = file_content_moon_pkg()
  let moon_pkg_path = @path.Path::join(project_dir, "moon.pkg").to_string()
  match write_string_file(moon_pkg_path, moon_pkg_content) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }

  let gitignore_content = file_content_gitignore()
  let gitignore_path = @path.Path::join(project_dir, ".gitignore").to_string()
  write_string_file(gitignore_path, gitignore_content)
}
