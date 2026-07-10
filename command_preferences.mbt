///|
async fn prompt_preferred_field(
  label : String,
  current : String?,
  builtin_default : String,
) -> String? raise CliError {
  let current_display = preferred_display_value(current, builtin_default)
  println("\{label} [\{current_display}] (press Enter to keep):")
  let line = match read_line_from_stdin() {
    Some(line) => line
    None => raise CliError("failed to read input from stdin")
  }
  let value = line.trim().to_owned()
  if value.is_empty() {
    current
  } else {
    Some(value)
  }
}

///|
fn preferred_display_value(
  current : String?,
  builtin_default : String,
) -> String {
  current.unwrap_or("<unset> (effective: \{builtin_default})")
}

///|
async fn prompt_preferred_config(
  preferred : PreferredConfig,
) -> PreferredConfig raise CliError {
  let license = prompt_preferred_field(
    "default license",
    preferred.license,
    DEFAULT_LICENSE,
  )
  let repository_hosting = prompt_preferred_field(
    "default host",
    preferred.repository_hosting,
    DEFAULT_HOST,
  )
  let preferred_target = prompt_preferred_field(
    "default target",
    preferred.preferred_target,
    DEFAULT_TARGET,
  )
  {
    username: preferred.username,
    license,
    repository_hosting,
    preferred_target,
  }
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

  let updated_preferred = prompt_preferred_config(preferred)
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
  let repository_hosting = preferred_display_value(
    preferred.repository_hosting,
    DEFAULT_HOST,
  )
  let preferred_target = preferred_display_value(
    preferred.preferred_target,
    DEFAULT_TARGET,
  )
  (
    $|current preferences
    $|file: \{preferred_file}
    $|license: \{license}
    $|host: \{repository_hosting}
    $|target: \{preferred_target}
  )
}
