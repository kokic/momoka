///|
async fn read_line_from_stdin() -> String? {
  @stdio.stdin.read_until("\n")
}

///|
fn ensure_dir_recursive(path : String) -> Result[Unit, String] {
  if path.is_empty() {
    return Ok(())
  }
  if @fs.path_exists(path) {
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
fn write_string_file(path : String, content : String) -> Result[Unit, String] {
  Result::map_err(try? @fs.write_string_to_file(path, content), err => {
    "failed to write file \{path}: \{@debug.to_repr(err)}"
  })
}
