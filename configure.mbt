///|
async fn prompt_preferred_field(
  label : String,
  current : String?,
  builtin_default : String,
) -> String? raise CliError {
  let current_display = preferred_display_value(current, builtin_default)
  println("\{label} [\{current_display}] (press Enter to keep):")
  guard read_line_from_stdin() is Some(line) else {
    raise CliError("failed to read input from stdin")
  }
  let value = line.trim().to_owned()
  guard !value.is_empty() else { current }
  Some(value)
}

///|
fn preferred_display_value(
  current : String?,
  builtin_default : String,
) -> String {
  current.unwrap_or("<unset> (effective: \{builtin_default})")
}

///|
async fn PreferredConfig::interactive_prompt(
  self : PreferredConfig,
) -> PreferredConfig raise CliError {
  let username = prompt_preferred_field(
    "default username",
    self.username,
    "prompt on new/init",
  )
  let license = prompt_preferred_field(
    "default license",
    self.license,
    DEFAULT_LICENSE,
  )
  let host = prompt_preferred_field("default host", self.host, DEFAULT_HOST)
  let preferred_target = prompt_preferred_field(
    "default target",
    self.preferred_target,
    DEFAULT_TARGET,
  )
  { username, license, host, preferred_target, }
}

///|
async fn configure_preferred_defaults() -> Unit raise CliError {
  let (preferred_file, preferred) = load_current_preferences()

  println("configure preferred defaults")
  println("leave input empty to keep existing preference")

  let updated_preferred = preferred.interactive_prompt()
  updated_preferred.save(preferred_file)
  println("updated preferences in \{preferred_file}")
}

///|
async fn show_preferred_defaults() -> Unit raise CliError {
  let (preferred_file, preferred) = load_current_preferences()
  let username = preferred_display_value(
    preferred.username,
    "prompt on new/init",
  )
  let license = preferred_display_value(preferred.license, DEFAULT_LICENSE)
  let host = preferred_display_value(preferred.host, DEFAULT_HOST)
  let preferred_target = preferred_display_value(
    preferred.preferred_target,
    DEFAULT_TARGET,
  )
  println(
    (
      $|current preferences
      $|file: \{preferred_file}
      $|username: \{username}
      $|license: \{license}
      $|host: \{host}
      $|target: \{preferred_target}
    ),
  )
}
