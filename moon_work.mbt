///|
async fn read_moon_work_members(
  moon_work_path : String,
) -> Array[String] raise @core.CliError {
  guard path_exists(moon_work_path) else {
    raise @core.cli_error("moon.work not found: \{moon_work_path}")
  }
  let members = parse_work_members(read_string_file(moon_work_path))
  guard !members.is_empty() else {
    raise @core.cli_error("no members found in \{moon_work_path}")
  }
  members
}

///|
fn parse_work_members(content : String) -> Array[String] {
  let members : Array[String] = []
  let mut in_members = false
  for raw_line in content.split("\n") {
    let line = raw_line.trim()
    if !in_members {
      if line.has_prefix("members") {
        in_members = true
      }
      continue
    }
    guard !line.has_prefix("]") else { break }
    guard line.split_once("\"") is Some((_, rest)) &&
      rest.split_once("\"") is Some((member_path, _)) else {
      continue
    }
    members.push(member_path.to_owned())
  }
  members
}

///|
async fn resolve_module_dirs(
  paths : ArrayView[String],
) -> Array[String] raise @core.CliError {
  let module_dirs : Array[String] = []
  for path in paths {
    let project_dir = absolute_path(path)
    ensure_existing_dir(project_dir)
    module_dirs.append(resolve_project_module_dirs(project_dir))
  }
  module_dirs
}

///|
async fn resolve_project_module_dirs(
  project_dir : String,
) -> Array[String] raise @core.CliError {
  if path_exists(project_file_path(project_dir, "moon.mod")) {
    return [project_dir]
  }
  let moon_work_path = project_file_path(project_dir, "moon.work")
  guard path_exists(moon_work_path) else {
    raise @core.cli_error(
      "neither moon.mod nor moon.work found in \{project_dir}",
    )
  }
  let members = read_moon_work_members(moon_work_path)
  members.map(member_path => {
    @path.Path::normalize(@path.Path::join(project_dir, member_path)).to_string()
  })
}
