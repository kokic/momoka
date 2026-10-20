///|
async fn run_bump_request(
  paths : ArrayView[String],
) -> Unit raise @core.CliError {
  bump_modules(resolve_module_dirs(paths))
}

///|
async fn bump_modules(
  module_dirs : ArrayView[String],
) -> Unit raise @core.CliError {
  for module_dir in module_dirs {
    bump_module(module_dir)
  }
}

///|
async fn bump_module(module_dir : String) -> Unit raise @core.CliError {
  let moon_mod_path = project_file_path(module_dir, "moon.mod")
  let moon_mod = read_moon_mod(moon_mod_path)
  guard moon_mod.version is Some(before) else {
    raise @core.cli_error("no version = \"x.y.z\" found in \{moon_mod_path}")
  }
  guard bump_patch_version(before) is Some(after) else {
    raise @core.cli_error("invalid version in \{moon_mod_path}: \{before}")
  }
  let content = moon_mod.content.replace(
    old="version = \"" + before + "\"",
    new="version = \"" + after + "\"",
  )
  write_or_truncate_string_file(moon_mod_path, content)
  println(version_change_message(module_dir, before, after))
}

///|
fn bump_patch_version(version : String) -> String? {
  match version.split(".").collect() {
    [major, minor, patch] => {
      let patch = @string.parse_int(patch) catch { _ => return None }
      Some("\{major}.\{minor}.\{patch + 1}")
    }
    _ => None
  }
}
