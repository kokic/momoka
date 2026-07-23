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
  host : String?
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
fn PreferredConfig::empty() -> PreferredConfig {
  { username: None, license: None, host: None, preferred_target: None }
}

///|
fn PreferredKey::name(self : PreferredKey) -> String {
  match self {
    UsernameField => "username"
    LicenseField => "license"
    HostField => "host"
    TargetField => "target"
  }
}

///|
fn parse_preferred_value(line : String, key : PreferredKey) -> String? {
  let key_name = key.name()
  let prefix = "\{key_name} "
  guard line.has_prefix(prefix) else { None }
  let value = line.view(start_offset=prefix.length()).trim().to_owned()
  guard !value.is_empty() else { None }
  Some(value)
}

///|
fn parse_preferred_entry(line : String) -> PreferredEntry? {
  for key in [UsernameField, LicenseField, HostField, TargetField] {
    guard parse_preferred_value(line, key) is Some(value) else { continue }
    return Some({ key, value })
  }
  None
}

///|
fn PreferredConfig::apply_entry(
  self : PreferredConfig,
  entry : PreferredEntry,
) -> PreferredConfig {
  match entry.key {
    UsernameField => { ..self, username: Some(entry.value) }
    LicenseField => { ..self, license: Some(entry.value) }
    HostField => { ..self, host: Some(entry.value) }
    TargetField => { ..self, preferred_target: Some(entry.value) }
  }
}

///|
fn PreferredConfig::parse(content : String) -> PreferredConfig {
  let mut preferred = PreferredConfig::empty()
  for raw_line in content.split("\n") {
    let line = raw_line.trim().to_owned()
    guard !line.is_empty() else { continue }
    guard parse_preferred_entry(line) is Some(entry) else { continue }
    preferred = preferred.apply_entry(entry)
  }
  preferred
}

///|
fn PreferredConfig::to_content(self : PreferredConfig) -> String {
  let lines : Array[String] = []
  push_preferred_line(lines, UsernameField, self.username)
  push_preferred_line(lines, LicenseField, self.license)
  push_preferred_line(lines, HostField, self.host)
  push_preferred_line(lines, TargetField, self.preferred_target)
  lines.join("\n")
}

///|
fn push_preferred_line(
  lines : Array[String],
  key : PreferredKey,
  value : String?,
) -> Unit {
  if value is Some(value) {
    lines.push("\{key.name()} \{value}")
  }
}

///|
async fn load_preferred_config(
  preferred_file : String,
) -> PreferredConfig raise CliError {
  guard path_exists(preferred_file) else { PreferredConfig::empty() }
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
        text => PreferredConfig::parse(text)
      }
  }
}

///|
async fn save_preferred_config(
  preferred_file : String,
  preferred : PreferredConfig,
) -> Unit raise CliError {
  write_or_truncate_string_file(preferred_file, preferred.to_content())
}
