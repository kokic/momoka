///|
fn preferred_dir_path(home : String) -> String {
  @path.Path::join(home, ".momoka").to_string()
}

///|
fn preferred_file_path(home : String) -> String {
  @path.Path::join(preferred_dir_path(home), "preferred.json").to_string()
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
fn PreferredConfig::empty() -> PreferredConfig {
  { username: None, license: None, host: None, preferred_target: None }
}

///|
fn PreferredKey::name(self : PreferredKey) -> String {
  match self {
    UsernameField => "username"
    LicenseField => "license"
    HostField => "host"
    TargetField => "preferred_target"
  }
}

///|
fn PreferredConfig::parse(content : String) -> PreferredConfig raise CliError {
  let json = try @json.parse(content) catch {
    err => raise CliError("failed to parse preferences JSON: \{err}")
  } noraise {
    json => json
  }
  guard json is Object(obj) else {
    raise CliError("expected preferences JSON object")
  }
  {
    username: string_field(obj, UsernameField),
    license: string_field(obj, LicenseField),
    host: string_field(obj, HostField),
    preferred_target: string_field(obj, TargetField),
  }
}

///|
fn string_field(obj : Map[String, Json], key : PreferredKey) -> String? {
  match obj.get(key.name()) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
fn PreferredConfig::to_content(self : PreferredConfig) -> String {
  let obj : Map[String, Json] = Map([])
  push_string_field(obj, UsernameField, self.username)
  push_string_field(obj, LicenseField, self.license)
  push_string_field(obj, HostField, self.host)
  push_string_field(obj, TargetField, self.preferred_target)
  Json::object(obj).stringify(indent=2)
}

///|
fn push_string_field(
  obj : Map[String, Json],
  key : PreferredKey,
  value : String?,
) -> Unit {
  if value is Some(value) {
    obj[key.name()] = Json::string(value)
  }
}

///|
async fn load_preferred_config(
  preferred_file : String,
) -> PreferredConfig raise CliError {
  guard path_exists(preferred_file) else { PreferredConfig::empty() }
  let content = try @fs.read_file(preferred_file) catch {
    err =>
      raise CliError(
        "failed to read preferences \{preferred_file}: \{Repr(err)}",
      )
  } noraise {
    content => content
  }
  let text = try content.text() catch {
    err =>
      raise CliError(
        "failed to decode preferences \{preferred_file}: \{Repr(err)}",
      )
  } noraise {
    text => text
  }
  PreferredConfig::parse(text)
}

///|
async fn save_preferred_config(
  preferred_file : String,
  preferred : PreferredConfig,
) -> Unit raise CliError {
  write_or_truncate_string_file(preferred_file, preferred.to_content())
}
