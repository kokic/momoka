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
  { username: self.username, license, host, preferred_target }
}

///|
async fn configure_preferred_defaults() -> String raise CliError {
  guard home_dir() is Some(home) else {
    raise CliError("cannot locate home directory from HOME/USERPROFILE")
  }
  let preferred_dir = preferred_dir_path(home)
  ensure_dir(preferred_dir)
  let preferred_file = preferred_file_path(home)
  let preferred = load_preferred_config(preferred_file)

  println("configure preferred defaults")
  println("leave input empty to keep existing preference")

  let updated_preferred = preferred.interactive_prompt()
  save_preferred_config(preferred_file, updated_preferred)
  "updated preferences in \{preferred_file}"
}

///|
async fn show_preferred_defaults() -> String raise CliError {
  guard home_dir() is Some(home) else {
    raise CliError("cannot locate home directory from HOME/USERPROFILE")
  }
  let preferred_file = preferred_file_path(home)
  let preferred = load_preferred_config(preferred_file)
  let license = preferred_display_value(preferred.license, DEFAULT_LICENSE)
  let host = preferred_display_value(preferred.host, DEFAULT_HOST)
  let preferred_target = preferred_display_value(
    preferred.preferred_target,
    DEFAULT_TARGET,
  )
  (
    $|current preferences
    $|file: \{preferred_file}
    $|license: \{license}
    $|host: \{host}
    $|target: \{preferred_target}
  )
}
