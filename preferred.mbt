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
priv enum PreferredKey {
  UsernameField
  LicenseField
  HostField
  TargetField
}

///|
priv struct PreferredEntry {
  key : PreferredKey
  value : String
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
fn preferred_key_name(key : PreferredKey) -> String {
  match key {
    UsernameField => "username"
    LicenseField => "license"
    HostField => "host"
    TargetField => "target"
  }
}

///|
fn parse_preferred_value(line : String, key : PreferredKey) -> String? {
  let key = preferred_key_name(key)
  let prefix = "\{key} "
  guard line.has_prefix(prefix) else { None }
  let value = line.view(start_offset=prefix.length()).trim().to_owned()
  if value.is_empty() {
    None
  } else {
    Some(value)
  }
}

///|
fn parse_preferred_entry(line : String) -> PreferredEntry? {
  for key in [UsernameField, LicenseField, HostField, TargetField] {
    if parse_preferred_value(line, key) is Some(value) {
      return Some({ key, value })
    }
  }
  None
}

///|
fn apply_preferred_entry(
  preferred : PreferredConfig,
  entry : PreferredEntry,
) -> PreferredConfig {
  match entry.key {
    UsernameField =>
      {
        username: Some(entry.value),
        license: preferred.license,
        repository_hosting: preferred.repository_hosting,
        preferred_target: preferred.preferred_target,
      }
    LicenseField =>
      {
        username: preferred.username,
        license: Some(entry.value),
        repository_hosting: preferred.repository_hosting,
        preferred_target: preferred.preferred_target,
      }
    HostField =>
      {
        username: preferred.username,
        license: preferred.license,
        repository_hosting: Some(entry.value),
        preferred_target: preferred.preferred_target,
      }
    TargetField =>
      {
        username: preferred.username,
        license: preferred.license,
        repository_hosting: preferred.repository_hosting,
        preferred_target: Some(entry.value),
      }
  }
}

///|
fn parse_preferred_config(content : String) -> PreferredConfig {
  let mut preferred = empty_preferred_config()
  for raw_line in content.split("\n") {
    let line = raw_line.trim().to_owned()
    if line.is_empty() {
      continue
    }
    if parse_preferred_entry(line) is Some(entry) {
      preferred = apply_preferred_entry(preferred, entry)
    }
  }
  preferred
}

///|
fn preferred_config_to_content(preferred : PreferredConfig) -> String {
  let lines : Array[String] = []
  push_preferred_line(lines, UsernameField, preferred.username)
  push_preferred_line(lines, LicenseField, preferred.license)
  push_preferred_line(lines, HostField, preferred.repository_hosting)
  push_preferred_line(lines, TargetField, preferred.preferred_target)
  lines.join("\n")
}

///|
fn push_preferred_line(
  lines : Array[String],
  key : PreferredKey,
  value : String?,
) -> Unit {
  if value is Some(value) {
    lines.push("\{preferred_key_name(key)} \{value}")
  }
}

///|
async fn load_preferred_config(
  preferred_file : String,
) -> PreferredConfig raise CliError {
  match path_exists(preferred_file) {
    false => empty_preferred_config()
    true =>
      try @fs.read_file(preferred_file) catch {
        err =>
          raise CliError(
            "failed to read preferences \{preferred_file}: \{@debug.to_repr(err)}",
          )
      } noraise {
        content =>
          try content.text() catch {
            err =>
              raise CliError(
                "failed to decode preferences \{preferred_file}: \{@debug.to_repr(err)}",
              )
          } noraise {
            text => parse_preferred_config(text)
          }
      }
  }
}

///|
async fn save_preferred_config(
  preferred_file : String,
  preferred : PreferredConfig,
) -> Unit raise CliError {
  write_or_truncate_string_file(
    preferred_file,
    preferred_config_to_content(preferred),
  )
}

///|
async fn ensure_dir(path : String) -> Unit raise CliError {
  match path_exists(path) {
    true =>
      try @fs.kind(path) catch {
        err =>
          raise CliError(
            "failed to inspect directory \{path}: \{@debug.to_repr(err)}",
          )
      } noraise {
        Directory => ()
        _ => raise CliError("path exists but is not a directory: \{path}")
      }
    false =>
      try @fs.mkdir(path) catch {
        err =>
          raise CliError(
            "failed to create directory \{path}: \{@debug.to_repr(err)}",
          )
      } noraise {
        _ => ()
      }
  }
}

///|
fn module_name_from_project_dir(project_dir : String) -> String {
  let module_name = @path.Path::basename(project_dir).to_owned()
  if module_name.is_empty() {
    "moon-new-mini"
  } else {
    module_name
  }
}
