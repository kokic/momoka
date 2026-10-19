///|
async fn run_upgrade_request(
  paths : ArrayView[String],
) -> Unit raise @core.CliError {
  for path in paths {
    let project_dir = absolute_path(path)
    ensure_existing_dir(project_dir)
    let moon_mod_path = project_file_path(project_dir, "moon.mod")
    let moon_mod = read_moon_mod(moon_mod_path)
    println(
      upgrade_project_modules(project_dir, moon_mod_path, moon_mod.dependencies),
    )
  }
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
      let updated = read_moon_mod(moon_mod_path)
      let version_after = updated.dependency_version(name).unwrap_or("unknown")
      println(
        version_change_message(
          dependency.name,
          dependency.version,
          version_after,
        ),
      )
      continue
    }
    println(failure)
  }
  "upgraded dependencies in \{emph(project_dir)}"
}
