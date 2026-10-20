///|
const EVOL_COMMIT_MESSAGE : String = "chore: update dependencies and bump module patch versions"

///|
const EVOL_PR_BODY : String = "Update all module dependencies to their latest versions. Bump patch versions only for modules whose dependencies changed. All modules pass `moon check`."

///|
async fn EvolConfig::execute(self : EvolConfig) -> Unit raise @core.CliError {
  let module_dirs = resolve_module_dirs(self.paths)
  if self.create_pr {
    self.create_branch()
  }
  if upgrade_modules(module_dirs) {
    bump_modules(module_dirs)
  } else {
    println("no dependency versions changed; skipped bump")
  }
  check_modules(module_dirs)
  self.commit_changes()
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
async fn EvolConfig::create_branch(
  self : EvolConfig,
) -> Unit raise @core.CliError {
  for project_dir in self.project_dirs() {
    run_git(project_dir, ["checkout", "-b", "update-dependencies"])
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
async fn EvolConfig::commit_changes(
  self : EvolConfig,
) -> Unit raise @core.CliError {
  for project_dir in self.project_dirs() {
    run_git(project_dir, ["add", "."])
    guard has_staged_changes(project_dir) else {
      println("no changes to commit in \{project_dir}; skipped commit")
      continue
    }
    run_git(project_dir, ["commit", "-m", EVOL_COMMIT_MESSAGE])
    guard self.create_pr else { continue }
    run_git(project_dir, ["push", "-u", "origin", "update-dependencies"])
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
