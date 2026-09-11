///|
const MAX_USERNAME_RETRIES : Int = 5

///|
async fn prompt_username(remaining_retry : Int) -> String raise CliError {
  guard remaining_retry > 0 else {
    raise CliError("failed to read username from stdin")
  }
  println("please input MoonBit username:")
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
  let (preferred_file, preferred) = load_current_preferences()
  guard preferred.username is Some(username) else {
    let prompted_username = prompt_username(MAX_USERNAME_RETRIES)
    let updated_preferred : PreferredConfig = {
      ..preferred,
      username: Some(prompted_username),
    }
    updated_preferred.save(preferred_file)
    { username: prompted_username, preferred: updated_preferred, }
  }
  UserPreferences::{ username, preferred, }
}
