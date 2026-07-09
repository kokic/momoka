///|
async fn read_line_from_stdin() -> Result[String?, String] {
  try @stdio.stdin.read_until("\n") catch {
    err => Err("failed to read input from stdin: \{@debug.to_repr(err)}")
  } noraise {
    line => Ok(line)
  }
}

///|
fn absolute_path(path : String) -> Result[String, String] {
  if @path.Path::is_absolute(path) {
    Ok(@path.Path::normalize(path).to_string())
  } else {
    guard @env.current_dir() is Some(cwd) else {
      return Err("cannot locate current directory")
    }
    Ok(@path.Path::normalize(@path.Path::join(cwd, path)).to_string())
  }
}

///|
async fn path_exists(path : String) -> Result[Bool, String] {
  try @fs.exists(path) catch {
    err => Err("failed to check path \{path}: \{@debug.to_repr(err)}")
  } noraise {
    exists => Ok(exists)
  }
}

///|
async fn ensure_dir_recursive(path : String) -> Result[Unit, String] {
  guard !path.is_empty() else { Ok(()) }
  match path_exists(path) {
    Ok(true) => return ensure_dir(path)
    Ok(false) => ()
    Err(err) => return Err(err)
  }
  let parent = @path.Path::dirname(path).to_string()
  if !parent.is_empty() && parent != path {
    match ensure_dir_recursive(parent) {
      Ok(_) => ()
      Err(err) => return Err(err)
    }
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
