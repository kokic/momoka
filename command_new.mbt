///|
fn create_project(
  config : CliConfig,
  username : String,
  preferred : PreferredConfig,
) -> Result[String, String] {
  let project_dir = @path.Path::resolve(config.path).to_string()
  if @fs.path_exists(project_dir) {
    return Err(
      "path already exists: \{project_dir}; use --init to initialize an existing directory",
    )
  }
  match ensure_dir_recursive(project_dir) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  match write_project_files(project_dir, config, username, preferred) {
    Ok(_) => Ok(project_dir)
    Err(err) => Err(err)
  }
}

///|
fn init_project(
  config : CliConfig,
  username : String,
  preferred : PreferredConfig,
) -> Result[String, String] {
  let project_dir = @path.Path::resolve(config.path).to_string()
  match ensure_existing_dir(project_dir) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  match write_project_files(project_dir, config, username, preferred) {
    Ok(_) => Ok(project_dir)
    Err(err) => Err(err)
  }
}

///|
fn ensure_existing_dir(path : String) -> Result[Unit, String] {
  if !@fs.path_exists(path) {
    return Err("directory does not exist: \{path}")
  }
  let is_dir_result = try? @fs.is_dir(path)
  match is_dir_result {
    Ok(true) => Ok(())
    Ok(false) => Err("path exists but is not a directory: \{path}")
    Err(err) => Err("failed to inspect directory \{path}: \{@debug.to_repr(err)}")
  }
}

///|
fn write_project_files(
  project_dir : String,
  config : CliConfig,
  username : String,
  preferred : PreferredConfig,
) -> Result[Unit, String] {
  let module_name = module_name_from_project_dir(project_dir)
  let license = Option::unwrap_or(
    config.license,
    Option::unwrap_or(preferred.license, "AGPL-3.0"),
  )
  let repository_hosting = Option::unwrap_or(
    config.repository_hosting,
    Option::unwrap_or(preferred.repository_hosting, "github.com"),
  )
  let preferred_target = Option::unwrap_or(
    config.preferred_target,
    Option::unwrap_or(preferred.preferred_target, "native"),
  )
  let moon_mod_content = file_content_moon_mod_json(
    username~,
    module_name~,
    license,
    repository_hosting,
    preferred_target,
  )
  let moon_mod_path = @path.Path::join(project_dir, "moon.mod.json").to_string()
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
  match write_string_file(gitignore_path, gitignore_content) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  Ok(())
}
