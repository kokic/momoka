///|
#cfg(target="native")
async fn read_line_from_stdin() -> String? raise @core.CliError {
  @stdio.stdin.read_until("\n") catch {
    err => raise @core.cli_error("failed to read input from stdin: \{(err)}")
  }
}

///|
fn absolute_path(path : String) -> String raise @core.CliError {
  guard !@path.Path::is_absolute(path) else {
    @path.Path::normalize(path).to_string()
  }
  guard @env.current_dir() is Some(cwd) else {
    raise @core.cli_error("cannot locate current directory")
  }
  @path.Path::normalize(@path.Path::join(cwd, path)).to_string()
}

///|
async fn path_exists(path : String) -> Bool raise @core.CliError {
  @fs.exists(path) catch {
    err => raise @core.cli_error("failed to check path \{path}: \{(err)}")
  }
}

///|
async fn ensure_dir_recursive(path : String) -> Unit raise @core.CliError {
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
) -> Unit raise @core.CliError {
  guard !path_exists(path) else {
    raise @core.cli_error("file already exists: \{path}")
  }
  @fs.write_file(path, content, create_mode=CreateNew) catch {
    err => raise @core.cli_error("failed to write file \{path}: \{(err)}")
  }
}

///|
#cfg(target="native")
async fn write_or_truncate_string_file(
  path : String,
  content : String,
) -> Unit raise @core.CliError {
  @fs.write_file(path, content, create_mode=CreateOrTruncate) catch {
    err => raise @core.cli_error("failed to write file \{path}: \{(err)}")
  }
}

///|
#cfg(target="native")
fn home_dir() -> String? {
  let home = @env.get_env_var("HOME")
  guard home is Some(path) && !path.is_empty() else {
    let userprofile = @env.get_env_var("USERPROFILE")
    guard userprofile is Some(path) && !path.is_empty() else { None }
    Some(path)
  }
  Some(path)
}

///|
async fn verify_is_directory(path : String) -> Unit raise @core.CliError {
  try @fs.kind(path) catch {
    err => raise @core.cli_error("failed to inspect directory \{path}: \{err}")
  } noraise {
    Directory => ()
    _ => raise @core.cli_error("path exists but is not a directory: \{path}")
  }
}

///|
async fn ensure_dir(path : String) -> Unit raise @core.CliError {
  guard !path_exists(path) else { verify_is_directory(path) }
  @fs.mkdir(path) catch {
    err => raise @core.cli_error("failed to create directory \{path}: \{(err)}")
  }
}

///|
async fn ensure_existing_dir(path : String) -> Unit raise @core.CliError {
  guard path_exists(path) else {
    raise @core.cli_error("directory does not exist: \{path}")
  }
  verify_is_directory(path)
}
