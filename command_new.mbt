///|
async fn create_project(
  config : CliConfig,
  username : String,
  preferred : PreferredConfig,
) -> Result[String, String] {
  let project_dir = @fs.realpath(config.path).to_string()
  if @fs.exists(project_dir) {
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
async fn init_project(
  config : CliConfig,
  username : String,
  preferred : PreferredConfig,
) -> Result[String, String] {
  let project_dir = @fs.realpath(config.path).to_string()
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
async fn ensure_existing_dir(path : String) -> Result[Unit, String] {
  guard @fs.exists(path) else {
    return Err("directory does not exist: \{path}")
  }

  match @fs.kind(path) {
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
