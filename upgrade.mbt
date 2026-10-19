///|
priv struct Dependency {
  name : String
  version : String
}

///|
fn Dependency::version_change(
  self : Dependency,
  version_after : String,
) -> String {
  let colored_before = @chalk.chalk().modifier(Dim).render(self.version)
  guard version_after != self.version else {
    return "\{emph(self.name)}: \{colored_before} -> \{colored_before}"
  }
  let colored_after = @chalk.chalk().color(Green).render(version_after)
  "\{emph(self.name)}: \{colored_before} -> \{colored_after}"
}

///|
async fn run_upgrade_request(
  paths : ArrayView[String],
) -> Unit raise @core.CliError {
  for path in paths {
    let project_dir = absolute_path(path)
    ensure_existing_dir(project_dir)
    let moon_mod_path = project_file_path(project_dir, "moon.mod")
    let dependencies = imported_modules_from_moon_mod(moon_mod_path)
    println(upgrade_project_modules(project_dir, moon_mod_path, dependencies))
  }
}

///|
async fn imported_modules_from_moon_mod(
  moon_mod_path : String,
) -> Array[Dependency] raise @core.CliError {
  guard path_exists(moon_mod_path) else {
    raise @core.cli_error("moon.mod not found: \{moon_mod_path}")
  }
  try @fs.read_file(moon_mod_path) catch {
    err => raise @core.cli_error("failed to read \{moon_mod_path}: \{err}")
  } noraise {
    content =>
      try content.text() catch {
        err =>
          raise @core.cli_error(
            "failed to decode \{moon_mod_path}: \{Repr(err)}",
          )
      } noraise {
        text => parse_import_dependencies(text)
      }
  }
}

///|
fn parse_import_dependencies(content : String) -> Array[Dependency] {
  let mut in_import = false
  let dependencies : Array[Dependency] = []
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
    guard dependency_from_import(entry) is Some(dependency) else { continue }
    dependencies.push(dependency)
    if line.contains("}") {
      in_import = false
    }
  }
  dependencies
}

///|
fn quoted_import_content(line : String) -> String? {
  guard line.split_once("\"") is Some((_, rest)) else { return None }
  guard rest.split_once("\"") is Some((content, _)) else { return None }
  guard !content.is_empty() else { return None }
  Some(content.to_owned())
}

///|
fn dependency_from_import(entry : String) -> Dependency? {
  guard !entry.has_prefix(".") &&
    !entry.has_prefix("/") &&
    !entry.contains("://") else {
    None
  }
  match entry.split_once("@") {
    Some((name, version)) if !name.is_empty() && !version.is_empty() =>
      Some({ name: name.to_owned(), version: version.to_owned(), })
    None if !entry.is_empty() => Some({ name: entry, version: "unknown", })
    _ => None
  }
}

///|
fn dependency_version(
  dependencies : ArrayView[Dependency],
  name : String,
) -> String? {
  for dependency in dependencies {
    guard dependency.name == name else { continue }
    return Some(dependency.version)
  }
  None
}

///|
fn upgrade_outcome_message(
  name : String,
  outcome : Result[Int32, String],
) -> String? {
  match outcome {
    Err(message) =>
      Some("failed to run `moon add \{name} --upgrade`: \{message}")
    Ok(status) =>
      if status == 0 {
        None
      } else {
        Some("`moon add \{name} --upgrade` failed with exit code \{status}")
      }
  }
}

///|
async fn upgrade_project_modules(
  project_dir : String,
  moon_mod_path : String,
  dependencies : ArrayView[Dependency],
) -> String raise @core.CliError {
  if dependencies.is_empty() {
    return "no dependencies to upgrade in \{project_dir}"
  }
  for dependency in dependencies {
    let name = dependency.name
    let outcome = try
      @process.run("moon", ["add", name, "--upgrade"], cwd=project_dir)
    catch {
      err => Err("\{err}")
    } noraise {
      status => Ok(status)
    }
    guard upgrade_outcome_message(name, outcome) is Some(failure) else {
      let updated = imported_modules_from_moon_mod(moon_mod_path)
      let version_after = dependency_version(updated, name).unwrap_or("unknown")
      println(dependency.version_change(version_after))
      continue
    }
    println(failure)
  }
  "upgraded \{dependencies.length()} dependencies in \{project_dir}"
}
