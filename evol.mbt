///|
const EVOL_COMMIT_MESSAGE : String = "chore: update dependencies and bump module patch versions"

///|
const EVOL_PR_BODY : String = "Update the selected modules' dependencies to their latest versions. Bump patch versions for all selected modules when any dependency changed. All selected modules pass `moon check`."

///|
async fn EvolConfig::execute(self : EvolConfig) -> Unit raise @core.CliError {
  let module_dirs = resolve_module_dirs(self.paths)
  match self.scope {
    SharedRepository => evolve_repository(module_dirs, self.create_pr)
    IndependentModules => {
      let failures : Array[String] = []
      for module_dir in module_dirs {
        evolve_repository([module_dir], self.create_pr) catch {
          err => {
            println("evol failed in \{module_dir}: \{Repr(err)}")
            failures.push(module_dir)
          }
        }
      }
      guard failures.is_empty() else {
        raise @core.cli_error("evol failed for modules: \{failures.join(", ")}")
      }
    }
  }
}

///|
async fn evolve_repository(
  module_dirs : ArrayView[String],
  create_pr : Bool,
) -> Unit raise @core.CliError {
  guard module_dirs.length() > 0 else { return }
  let project_dir = repository_dir(module_dirs[0])
  let dependencies_changed = upgrade_modules(module_dirs)
  if dependencies_changed {
    if create_pr {
      run_program("git", ["checkout", "-b", "update-dependencies"], project_dir)
    }
    bump_modules(module_dirs)
  } else {
    println("no dependency versions changed; skipped bump")
  }
  check_modules(module_dirs)
  if create_pr {
    guard dependencies_changed else {
      println("no dependency versions changed; skipped commit")
      return
    }
  }
  commit_repository(project_dir, create_pr)
}

///|
async fn repository_dir(module_dir : String) -> String raise @core.CliError {
  let (status, output) = @process.collect_stdout(
    "git",
    ["rev-parse", "--show-toplevel"],
    cwd=module_dir,
  ) catch {
    err =>
      raise @core.cli_error(
        "failed to locate repository for \{module_dir}: \{err}",
      )
  }
  guard status == 0 else {
    raise @core.cli_error(
      "`git rev-parse --show-toplevel` failed in \{module_dir} with exit code \{status}",
    )
  }
  let path = output.text() catch {
    err =>
      raise @core.cli_error(
        "failed to decode repository path for \{module_dir}: \{err}",
      )
  }
  path.trim_end(chars="\n\r").to_owned()
}

///|
async fn check_modules(
  module_dirs : ArrayView[String],
) -> Unit raise @core.CliError {
  for module_dir in module_dirs {
    let status = @process.run("moon", ["check"], cwd=module_dir) catch {
      err => raise @core.cli_error("failed to run `moon check`: \{err}")
    }
    guard status == 0 else {
      raise @core.cli_error("`moon check` failed with exit code \{status}")
    }
  }
}

///|
async fn commit_repository(
  project_dir : String,
  create_pr : Bool,
) -> Unit raise @core.CliError {
  run_program("git", ["add", "."], project_dir)
  guard has_staged_changes(project_dir) else {
    println("no changes to commit in \{project_dir}; skipped commit")
    return
  }
  run_program("git", ["commit", "-m", EVOL_COMMIT_MESSAGE], project_dir)
  guard create_pr else { return }
  run_program(
    "git",
    ["push", "-u", "origin", "update-dependencies"],
    project_dir,
  )
  run_program(
    "gh",
    [
      "pr",
      "create",
      "--draft",
      "--title",
      EVOL_COMMIT_MESSAGE,
      "--body",
      EVOL_PR_BODY,
    ],
    project_dir,
  )
  run_program("git", ["checkout", "main"], project_dir)
}

///|
async fn has_staged_changes(project_dir : String) -> Bool raise @core.CliError {
  let status = @process.run(
    "git",
    ["diff", "--cached", "--quiet"],
    cwd=project_dir,
  ) catch {
    err =>
      raise @core.cli_error("failed to run `git diff --cached --quiet`: \{err}")
  }
  match status {
    0 => false
    1 => true
    _ =>
      raise @core.cli_error(
        "`git diff --cached --quiet` failed with exit code \{status}",
      )
  }
}
