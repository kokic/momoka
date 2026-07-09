///|
async fn read_line_from_stdin() -> String? {
  @stdio.stdin.read_until("\n")
}

///|
async fn ensure_dir_recursive(path : String) -> Result[Unit, String] {
  guard !path.is_empty() else { Ok(()) }
  guard !@fs.exists(path) else { ensure_dir(path) }
  let parent = @path.Path::dirname(path).to_string()
  if !parent.is_empty() && parent != path {
    return ensure_dir_recursive(parent)
  }
  ensure_dir(path)
}

///|
async fn write_string_file(
  path : String,
  content : String,
) -> Result[Unit, String] {
  try @fs.write_file(path, content, create_mode=CreateOrTruncate) catch {
    err => Err("failed to write file \{path}: \{@debug.to_repr(err)}")
  } noraise {
    _ => Ok(())
  }
}

///|
fn home_dir() -> String? {
  let home = @sys.get_env_var("HOME")
  guard home is Some(path) && !path.is_empty() else {
    let userprofile = @sys.get_env_var("USERPROFILE")
    guard userprofile is Some(path) && !path.is_empty() else { None }
    Some(path)
  }
  Some(path)
}
