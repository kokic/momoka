///|
const MAX_USERNAME_RETRIES : Int = 5

///|
async fn prompt_username(remaining_retry : Int) -> String raise CliError {
  guard remaining_retry > 0 else {
    raise CliError("failed to read username from stdin")
  }
  println("(first) please input MoonBit username:")
  guard read_line_from_stdin() is Some(line) else {
    raise CliError("failed to read username from stdin")
  }
  let username = line.trim().to_owned()
  guard username.is_empty() else { username }
  println("username cannot be empty")
  prompt_username(remaining_retry - 1)
}

///|
priv struct UserPreferences {
  username : String
  preferred : PreferredConfig
}

///|
async fn ensure_username_with_preferred() -> UserPreferences raise CliError {
  guard home_dir() is Some(home) else {
    raise CliError("cannot locate home directory from HOME/USERPROFILE")
  }
  let preferred_dir = preferred_dir_path(home)
  let preferred_file = preferred_file_path(home)
  let preferred = load_preferred_config(preferred_file)
  guard preferred.username is Some(username) else {
    ensure_dir(preferred_dir)
    let prompted_username = prompt_username(MAX_USERNAME_RETRIES)
    let updated_preferred : PreferredConfig = {
      ..preferred,
      username: Some(prompted_username),
    }
    save_preferred_config(preferred_file, updated_preferred)
    { username: prompted_username, preferred: updated_preferred }
  }
  UserPreferences::{ username, preferred }
}
