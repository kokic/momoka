///|
async fn read_line_from_stdin() -> String? {
  @stdio.stdin.read_until("\n")
}

///|
async fn ensure_dir_recursive(path : String) -> Result[Unit, String] {
  if path.is_empty() {
    return Ok(())
  }
  if @fs.exists(path) {
    ensure_dir(path)
  } else {
    let parent = @path.Path::dirname(path).to_string()
    if !parent.is_empty() && parent != path {
      match ensure_dir_recursive(parent) {
        Ok(_) => ()
        Err(err) => return Err(err)
      }
    }
    ensure_dir(path)
  }
}

///|
async fn write_string_file(
  path : String,
  content : String,
) -> Result[Unit, String] {
  Result::map_err(try? @fs.write_file(path, content), err => {
    "failed to write file \{path}: \{@debug.to_repr(err)}"
  })
}

///|
fn home_dir() -> String? {
  let home = @sys.get_env_var("HOME")
  if home is Some(path) && !path.is_empty() {
    Some(path)
  } else {
    let userprofile = @sys.get_env_var("USERPROFILE")
    if userprofile is Some(path) && !path.is_empty() {
      Some(path)
    } else {
      None
    }
  }
}
