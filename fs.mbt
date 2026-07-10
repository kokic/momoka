///|
async fn read_line_from_stdin() -> String? raise CliError {
  try @stdio.stdin.read_until("\n") catch {
    err =>
      raise CliError("failed to read input from stdin: \{@debug.to_repr(err)}")
  } noraise {
    line => line
  }
}

///|
fn absolute_path(path : String) -> String raise CliError {
  guard !@path.Path::is_absolute(path) else {
    @path.Path::normalize(path).to_string()
  }
  guard @env.current_dir() is Some(cwd) else {
    raise CliError("cannot locate current directory")
  }
  @path.Path::normalize(@path.Path::join(cwd, path)).to_string()
}

///|
async fn path_exists(path : String) -> Bool raise CliError {
  try @fs.exists(path) catch {
    err =>
      raise CliError("failed to check path \{path}: \{@debug.to_repr(err)}")
  } noraise {
    exists => exists
  }
}

///|
async fn ensure_dir_recursive(path : String) -> Unit raise CliError {
  guard !path.is_empty() else { () }
  guard !path_exists(path) else { ensure_dir(path) }
  let parent = @path.Path::dirname(path).to_string()
  if !parent.is_empty() && parent != path {
    ensure_dir_recursive(parent)
  }
  ensure_dir(path)
}

///|
async fn write_new_string_file(
  path : String,
  content : String,
) -> Unit raise CliError {
  guard !path_exists(path) else {
    raise CliError("file already exists: \{path}")
  }
  try @fs.write_file(path, content, create_mode=CreateNew) catch {
    err =>
      raise CliError("failed to write file \{path}: \{@debug.to_repr(err)}")
  } noraise {
    _ => ()
  }
}

///|
async fn write_or_truncate_string_file(
  path : String,
  content : String,
) -> Unit raise CliError {
  try @fs.write_file(path, content, create_mode=CreateOrTruncate) catch {
    err =>
      raise CliError("failed to write file \{path}: \{@debug.to_repr(err)}")
  } noraise {
    _ => ()
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
