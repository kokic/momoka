///|
const EVOL_COMMIT_MESSAGE : String = "chore: update dependencies and bump module patch versions"

///|
const EVOL_PR_BODY : String = "Update all module dependencies to their latest versions. Bump patch versions only for modules whose dependencies changed. All modules pass `moon check`."

///|
async fn EvolConfig::execute(self : EvolConfig) -> Unit raise @core.CliError {
  let project_dirs = self.project_dirs()
  let module_dirs = resolve_module_dirs(self.paths)
  let dependencies_changed = upgrade_modules(module_dirs)
  if dependencies_changed {
    if self.create_pr {
      create_branches(project_dirs)
    }
    bump_modules(module_dirs)
  } else {
    println("no dependency versions changed; skipped bump")
  }
  check_modules(module_dirs)
  if self.create_pr {
    guard dependencies_changed else {
      println("no dependency versions changed; skipped commit")
      return
    }
  }
  commit_changes(project_dirs, self.create_pr)
}

///|
fn EvolConfig::project_dirs(
  self : EvolConfig,
) -> Array[String] raise @core.CliError {
  let project_dirs : Array[String] = []
  for path in self.paths {
    project_dirs.push(absolute_path(path))
  }
  project_dirs
}

///|
async fn create_branches(
  project_dirs : ArrayView[String],
) -> Unit raise @core.CliError {
  for project_dir in project_dirs {
    run_program("git", ["checkout", "-b", "update-dependencies"], project_dir)
  }
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
async fn commit_changes(
  project_dirs : ArrayView[String],
  create_pr : Bool,
) -> Unit raise @core.CliError {
  for project_dir in project_dirs {
    run_program("git", ["add", "."], project_dir)
    guard has_staged_changes(project_dir) else {
      println("no changes to commit in \{project_dir}; skipped commit")
      continue
    }
    run_program("git", ["commit", "-m", EVOL_COMMIT_MESSAGE], project_dir)
    guard create_pr else { continue }
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
  }
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
