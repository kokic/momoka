///|
async fn prompt_username(remaining_retry : Int) -> Result[String, String] {
  if remaining_retry <= 0 {
    Err("failed to read username from stdin")
  } else {
    println("(first) please input MoonBit username:")
    match read_line_from_stdin() {
      Ok(Some(line)) => {
        let username = line.trim().to_owned()
        if username.is_empty() {
          println("username cannot be empty")
          prompt_username(remaining_retry - 1)
        } else {
          Ok(username)
        }
      }
      Ok(None) => Err("failed to read username from stdin")
      Err(err) => Err(err)
    }
  }
}

///|
async fn ensure_username() -> Result[String, String] {
  guard home_dir() is Some(home) else {
    return Err("cannot locate home directory from HOME/USERPROFILE")
  }
  let preferred_dir = preferred_dir_path(home)
  let preferred_file = preferred_file_path(home)
  let preferred = load_preferred_config(preferred_file)
  if preferred.username is Some(username) {
    Ok(username)
  } else {
    match ensure_dir(preferred_dir) {
      Ok(_) => ()
      Err(err) => return Err(err)
    }
    let username = match prompt_username(5) {
      Ok(username) => username
      Err(err) => return Err(err)
    }
    let updated_preferred : PreferredConfig = {
      username: Some(username),
      license: preferred.license,
      repository_hosting: preferred.repository_hosting,
      preferred_target: preferred.preferred_target,
    }
    save_preferred_config(preferred_file, updated_preferred).map(_ => username)
  }
}
