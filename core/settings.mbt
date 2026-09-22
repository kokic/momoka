///|
pub struct ProjectOverrides {
  username : String?
  license : String?
  host : String?
  preferred_target : String?
}

///|
pub struct ProjectSettings {
  license : String
  host : String
  preferred_target : String
}

///|
pub fn ProjectSettings::new(
  license : String,
  host : String,
  preferred_target : String,
) -> ProjectSettings {
  { license, host, preferred_target, }
}

///|
pub fn configured_value(
  explicit : String?,
  preferred : String?,
  builtin : String,
) -> String {
  explicit.unwrap_or(preferred.unwrap_or(builtin))
}
