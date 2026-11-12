///|
#derive(Debug)
pub suberror CliError {
  CliError(String)
}

///|
pub extend CliError with Debug::{to_repr}

///|
pub fn cli_error(message : String) -> CliError {
  CliError(message)
}
