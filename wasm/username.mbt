///|
const GUEST_USERNAME : String = "guest"

///|
fn ensure_username(explicit_username : String?) -> String raise @core.CliError {
  if explicit_username is Some(value) {
    let username = value.trim().to_owned()
    guard !username.is_empty() else {
      raise @core.cli_error("username cannot be empty")
    }
    return username
  }
  println("no --username provided; falling back to \"\{GUEST_USERNAME}\"")
  GUEST_USERNAME
}
