///|
fn preferred_dir_path(home : String) -> String {
  @path.Path::join(home, ".moon-mini").to_string()
}

///|
fn preferred_file_path(home : String) -> String {
  @path.Path::join(preferred_dir_path(home), "preferred.txt").to_string()
}

///|
priv struct PreferredConfig {
  username : String?
  license : String?
  repository_hosting : String?
  preferred_target : String?
}

///|
fn empty_preferred_config() -> PreferredConfig {
  {
    username: None,
    license: None,
    repository_hosting: None,
    preferred_target: None,
  }
}

///|
fn parse_preferred_field(line : String, key : String) -> String? {
  let prefix = "\{key} "
  if !line.has_prefix(prefix) {
    return None
  }
  let value = line.view(start_offset=prefix.length()).trim().to_string()
  if value.is_empty() {
    None
  } else {
    Some(value)
  }
}

///|
fn parse_preferred_config(content : String) -> PreferredConfig {
  let mut username : String? = None
  let mut license : String? = None
  let mut repository_hosting : String? = None
  let mut preferred_target : String? = None
  for raw_line in content.split("\n") {
    let line = raw_line.trim().to_string()
    if line.is_empty() {
      continue
    }
    if parse_preferred_field(line, "username") is Some(value) {
      username = Some(value)
    } else if parse_preferred_field(line, "license") is Some(value) {
      license = Some(value)
    } else if parse_preferred_field(line, "host") is Some(value) {
      repository_hosting = Some(value)
    } else if parse_preferred_field(line, "target") is Some(value) {
      preferred_target = Some(value)
    }
  }
  { username, license, repository_hosting, preferred_target }
}

///|
fn preferred_config_to_content(preferred : PreferredConfig) -> String {
  let lines : Array[String] = []
  if preferred.username is Some(value) {
    lines.push("username \{value}")
  }
  if preferred.license is Some(value) {
    lines.push("license \{value}")
  }
  if preferred.repository_hosting is Some(value) {
    lines.push("host \{value}")
  }
  if preferred.preferred_target is Some(value) {
    lines.push("target \{value}")
  }
  lines.join("\n")
}

///|
async fn load_preferred_config(preferred_file : String) -> PreferredConfig {
  if !@fs.exists(preferred_file) {
    empty_preferred_config()
  } else {
    (try? @fs.read_file(preferred_file))
    .to_option()
    .map(content => parse_preferred_config(content.text()))
    .unwrap_or(empty_preferred_config())
  }
}

///|
async fn save_preferred_config(
  preferred_file : String,
  preferred : PreferredConfig,
) -> Result[Unit, String] {
  write_string_file(preferred_file, preferred_config_to_content(preferred))
}

///|
async fn ensure_dir(path : String) -> Result[Unit, String] {
  if @fs.exists(path) {
    try @fs.kind(path) catch {
      err => Err("failed to inspect directory \{path}: \{@debug.to_repr(err)}")
    } noraise {
      Directory => Ok(())
      _ => Err("path exists but is not a directory: \{path}")
    }
  } else {
    Result::map_err(try? @fs.mkdir(path), err => {
      "failed to create directory \{path}: \{@debug.to_repr(err)}"
    })
  }
}

///|
fn module_name_from_project_dir(project_dir : String) -> String {
  let module_name = @path.Path::basename(project_dir).to_string()
  if module_name.is_empty() {
    "moon-new-mini"
  } else {
    module_name
  }
}
