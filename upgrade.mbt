///|
async fn run_upgrade_request(path : String) -> String raise CliError {
  let project_dir = absolute_path(path)
  ensure_existing_dir(project_dir)
  let moon_mod_path = project_file_path(project_dir, "moon.mod")
  let mod_names = import_modules_from_moon_mod(moon_mod_path)
  upgrade_project_modules(project_dir, mod_names)
}

///|
async fn import_modules_from_moon_mod(
  moon_mod_path : String,
) -> Array[String] raise CliError {
  guard path_exists(moon_mod_path) else {
    raise CliError("moon.mod not found: \{moon_mod_path}")
  }
  try @fs.read_file(moon_mod_path) catch {
    err => raise CliError("failed to read \{moon_mod_path}: \{err}")
  } noraise {
    content =>
      try content.text() catch {
        err =>
          raise CliError(
            "failed to decode \{moon_mod_path}: \{Repr(err)}",
          )
      } noraise {
        text => parse_import_modules(text)
      }
  }
}

///|
fn parse_import_modules(content : String) -> Array[String] {
  let mut in_import = false
  let mod_names : Array[String] = []
  for raw_line in content.split("\n") {
    let line = raw_line.trim().to_owned()
    if !in_import {
      guard line.has_prefix("import") && line.contains("{") else { continue }
      in_import = true
    }
    guard quoted_import_content(line) is Some(entry) else {
      if line.contains("}") {
        in_import = false
      }
      continue
    }
    guard module_name_from_import(entry) is Some(mod_name) else { continue }
    mod_names.push(mod_name)
    if line.contains("}") {
      in_import = false
    }
  }
  mod_names
}

///|
fn quoted_import_content(line : String) -> String? {
  guard line.split_once("\"") is Some((_, rest)) else { return None }
  guard rest.split_once("\"") is Some((content, _)) else { return None }
  guard !content.is_empty() else { return None }
  Some(content.to_owned())
}

///|
fn module_name_from_import(entry : String) -> String? {
  guard !entry.has_prefix(".") && !entry.has_prefix("/") && !entry.contains(
    "://",
  ) else {
    None
  }
  match entry.split_once("@") {
    Some((name, _)) if !name.is_empty() => Some(name.to_owned())
    None => Some(entry)
    _ => None
  }
}

///|
async fn upgrade_project_modules(
  project_dir : String,
  mod_names : ArrayView[String],
) -> String raise CliError {
  if mod_names.is_empty() {
    return "no dependencies to upgrade in \{project_dir}"
  }
  let status = try
    @process.run(
      "moon",
      ["add", ..mod_names, "--upgrade"],
      cwd=project_dir,
    )
  catch {
    err => raise CliError("failed to run moon add --upgrade: \{err}")
  } noraise {
    status => status
  }
  guard status == 0 else {
    raise CliError(
      "moon add \{mod_names.join(" ")} --upgrade failed with exit code \{status}",
    )
  }
  "upgraded \{mod_names.length()} dependencies in \{project_dir}: \{mod_names.join(", ")}"
}
