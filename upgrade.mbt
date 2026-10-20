///|
priv struct UpgradeReport {
  message : String
  changed : Bool
}

///|
async fn run_upgrade_request(
  paths : ArrayView[String],
) -> Bool raise @core.CliError {
  upgrade_modules(resolve_module_dirs(paths))
}

///|
async fn upgrade_modules(
  module_dirs : ArrayView[String],
) -> Bool raise @core.CliError {
  let mut changed = false
  for module_dir in module_dirs {
    let moon_mod_path = project_file_path(module_dir, "moon.mod")
    let moon_mod = read_moon_mod(moon_mod_path)
    let report = upgrade_module(
      module_dir,
      moon_mod_path,
      moon_mod.dependencies,
    )
    println(report.message)
    changed = report.changed || changed
  }
  changed
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
async fn upgrade_module(
  module_dir : String,
  moon_mod_path : String,
  dependencies : ArrayView[Dependency],
) -> UpgradeReport raise @core.CliError {
  if dependencies.is_empty() {
    return {
      message: "no dependencies to upgrade in \{module_dir}",
      changed: false,
    }
  }
  let mut changed = false
  for dependency in dependencies {
    let name = dependency.name
    let outcome = try
      @process.run("moon", ["add", name, "--upgrade"], cwd=module_dir)
    catch {
      err => Err("\{err}")
    } noraise {
      status => Ok(status)
    }
    guard upgrade_outcome_message(name, outcome) is Some(failure) else {
      let updated = read_moon_mod(moon_mod_path)
      let version_after = updated.dependency_version(name).unwrap_or("unknown")
      changed = changed || version_after != dependency.version
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
  { message: "upgraded dependencies in \{emph(module_dir)}", changed, }
}
