///|
suberror CliError {
  CliError(String)
} derive(Debug)

///|
pub extend CliError with Debug::{to_repr}
