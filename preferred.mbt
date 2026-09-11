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
fn PreferredConfig::empty() -> PreferredConfig {
  { username: None, license: None, host: None, preferred_target: None, }
}

///|
fn PreferredConfig::parse(content : String) -> PreferredConfig raise CliError {
  let json = @json.parse(content) catch {
    err => raise CliError("failed to parse preferences JSON: \{err}")
  }
  guard json is Object(obj) else {
    raise CliError("expected preferences JSON object")
  }
  {
    username: string_field(obj, "username"),
    license: string_field(obj, "license"),
    host: string_field(obj, "host"),
    preferred_target: string_field(obj, "preferred_target"),
  }
}

///|
fn string_field(obj : Map[String, Json], key : String) -> String? {
  guard obj.get(key) is Some(String(value)) else { None }
  Some(value)
}

///|
fn PreferredConfig::to_content(self : PreferredConfig) -> String {
  let obj : Map[String, Json] = Map([])
  push_string_field(obj, "username", self.username)
  push_string_field(obj, "license", self.license)
  push_string_field(obj, "host", self.host)
  push_string_field(obj, "preferred_target", self.preferred_target)
  Json::object(obj).stringify(indent=2)
}

///|
fn push_string_field(
  obj : Map[String, Json],
  key : String,
  value : String?,
) -> Unit {
  if value is Some(value) {
    obj[key] = Json::string(value)
  }
}

///|
async fn PreferredConfig::load(
  preferred_file : String,
) -> PreferredConfig raise CliError {
  guard path_exists(preferred_file) else { PreferredConfig::empty() }
  let content = @fs.read_file(preferred_file) catch {
    err =>
      raise CliError(
        "failed to read preferences \{preferred_file}: \{Repr(err)}",
      )
  }
  let text = content.text() catch {
    err =>
      raise CliError(
        "failed to decode preferences \{preferred_file}: \{Repr(err)}",
      )
  }
  PreferredConfig::parse(text)
}

///|
async fn PreferredConfig::save(
  self : PreferredConfig,
  preferred_file : String,
) -> Unit raise CliError {
  ensure_dir(@path.Path::dirname(preferred_file).to_string())
  write_or_truncate_string_file(preferred_file, self.to_content())
}

///|
async fn load_current_preferences() -> (String, PreferredConfig) raise CliError {
  guard home_dir() is Some(home) else {
    raise CliError("cannot locate home directory from HOME/USERPROFILE")
  }
  let preferred_file = preferred_file_path(home)
  (preferred_file, PreferredConfig::load(preferred_file))
}
