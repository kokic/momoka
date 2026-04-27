///|
async fn prompt_preferred_field(
  label : String,
  current : String?,
  builtin_default : String,
) -> Result[String?, String] {
  let current_display = preferred_display_value(current, builtin_default)
  println("\{label} [\{current_display}] (press Enter to keep):")
  guard read_line_from_stdin() is Some(line) else {
    return Err("failed to read input from stdin")
  }
  let value = line.trim().to_owned()
  if value.is_empty() {
    Ok(current)
  } else {
    Ok(Some(value))
  }
}

///|
fn preferred_display_value(
  current : String?,
  builtin_default : String,
) -> String {
  match current {
    Some(value) => value
    None => "<unset> (effective: \{builtin_default})"
  }
}

///|
async fn configure_preferred_defaults() -> Result[String, String] {
  guard home_dir() is Some(home) else {
    return Err("cannot locate home directory from HOME/USERPROFILE")
  }
  let preferred_dir = preferred_dir_path(home)
  match ensure_dir(preferred_dir) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  let preferred_file = preferred_file_path(home)
  let preferred = load_preferred_config(preferred_file)

  println("configure preferred defaults")
  println("leave input empty to keep existing preference")

  let license = match
    prompt_preferred_field("default license", preferred.license, "AGPL-3.0") {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let repository_hosting = match
    prompt_preferred_field(
      "default host",
      preferred.repository_hosting,
      "github.com",
    ) {
    Ok(value) => value
    Err(err) => return Err(err)
  }
  let preferred_target = match
    prompt_preferred_field(
      "default target",
      preferred.preferred_target,
      "native",
    ) {
    Ok(value) => value
    Err(err) => return Err(err)
  }

  let updated_preferred : PreferredConfig = {
    username: preferred.username,
    license,
    repository_hosting,
    preferred_target,
  }
  match save_preferred_config(preferred_file, updated_preferred) {
    Ok(_) => Ok("updated preferences in \{preferred_file}")
    Err(err) => Err(err)
  }
}

///|
async fn show_preferred_defaults() -> Result[String, String] {
  guard home_dir() is Some(home) else {
    return Err("cannot locate home directory from HOME/USERPROFILE")
  }
  let preferred_file = preferred_file_path(home)
  let preferred = load_preferred_config(preferred_file)
  let license = preferred_display_value(preferred.license, "AGPL-3.0")
  let repository_hosting = preferred_display_value(
    preferred.repository_hosting,
    "github.com",
  )
  let preferred_target = preferred_display_value(
    preferred.preferred_target,
    "native",
  )
  Ok(
    (
      #|current preferences
      $|file: \{preferred_file}
      $|license: \{license}
      $|host: \{repository_hosting}
      $|target: \{preferred_target}
    ),
  )
}
