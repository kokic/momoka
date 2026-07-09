///|
async fn prompt_preferred_field(
  label : String,
  current : String?,
  builtin_default : String,
) -> Result[String?, String] {
  let current_display = preferred_display_value(current, builtin_default)
  println("\{label} [\{current_display}] (press Enter to keep):")
  let line = match read_line_from_stdin() {
    Ok(Some(line)) => line
    Ok(None) => return Err("failed to read input from stdin")
    Err(err) => return Err(err)
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
  current.unwrap_or("<unset> (effective: \{builtin_default})")
}

///|
priv struct PreferredPromptField {
  label : String
  current : String?
  builtin_default : String
}

///|
async fn prompt_preferred_fields(
  fields : ArrayView[PreferredPromptField],
) -> Result[Array[String?], String] {
  let values : Array[String?] = []
  for field in fields {
    match
      prompt_preferred_field(field.label, field.current, field.builtin_default) {
      Ok(value) => values.push(value)
      Err(err) => return Err(err)
    }
  }
  Ok(values)
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
  let preferred = match load_preferred_config(preferred_file) {
    Ok(preferred) => preferred
    Err(err) => return Err(err)
  }

  println("configure preferred defaults")
  println("leave input empty to keep existing preference")

  let preferred_values = match
    prompt_preferred_fields([
      {
        label: "default license",
        current: preferred.license,
        builtin_default: DEFAULT_LICENSE,
      },
      {
        label: "default host",
        current: preferred.repository_hosting,
        builtin_default: DEFAULT_HOST,
      },
      {
        label: "default target",
        current: preferred.preferred_target,
        builtin_default: DEFAULT_TARGET,
      },
    ]) {
    Ok(values) => values
    Err(err) => return Err(err)
  }

  let updated_preferred : PreferredConfig = {
    username: preferred.username,
    license: preferred_values[0],
    repository_hosting: preferred_values[1],
    preferred_target: preferred_values[2],
  }
  save_preferred_config(preferred_file, updated_preferred).map(_ => {
    "updated preferences in \{preferred_file}"
  })
}

///|
async fn show_preferred_defaults() -> Result[String, String] {
  guard home_dir() is Some(home) else {
    return Err("cannot locate home directory from HOME/USERPROFILE")
  }
  let preferred_file = preferred_file_path(home)
  let preferred = match load_preferred_config(preferred_file) {
    Ok(preferred) => preferred
    Err(err) => return Err(err)
  }
  let license = preferred_display_value(preferred.license, DEFAULT_LICENSE)
  let repository_hosting = preferred_display_value(
    preferred.repository_hosting,
    DEFAULT_HOST,
  )
  let preferred_target = preferred_display_value(
    preferred.preferred_target,
    DEFAULT_TARGET,
  )
  Ok(
    (
      $|current preferences
      $|file: \{preferred_file}
      $|license: \{license}
      $|host: \{repository_hosting}
      $|target: \{preferred_target}
    ),
  )
}
