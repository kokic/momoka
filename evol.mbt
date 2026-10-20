///|
async fn run_evol_request(
  paths : ArrayView[String],
) -> Unit raise @core.CliError {
  if run_upgrade_request(paths) {
    run_bump_request(paths)
  } else {
    println("no dependency versions changed; skipped bump")
  }
  for path in paths {
    let project_dir = absolute_path(path)
    ensure_existing_dir(project_dir)
    let status = @process.run("moon", ["check"], cwd=project_dir) catch {
      err => raise @core.cli_error("failed to run `moon check`: \{err}")
    }
    guard status == 0 else {
      raise @core.cli_error("`moon check` failed with exit code \{status}")
    }
  }
}
