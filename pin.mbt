///|
async fn run_pin_request(
  paths : ArrayView[String],
) -> Unit raise @core.CliError {
  for path in paths {
    let project_dir = absolute_path(path)
    ensure_existing_dir(project_dir)
    run_program("git", ["add", "."], project_dir)
    run_program("git", ["commit", "-m", "chore: snapshot update"], project_dir)
    run_program("git", ["push"], project_dir)
  }
}
