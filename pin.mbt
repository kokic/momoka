///|
async fn run_pin_request(
  paths : ArrayView[String],
) -> Unit raise @core.CliError {
  for path in paths {
    let project_dir = absolute_path(path)
    ensure_existing_dir(project_dir)
    run_git(project_dir, ["add", "."])
    run_git(project_dir, ["commit", "-m", "chore: snapshot update"])
    run_git(project_dir, ["push"])
  }
}
