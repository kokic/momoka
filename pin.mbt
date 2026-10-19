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

///|
async fn run_git(
  project_dir : String,
  args : Array[String],
) -> Unit raise @core.CliError {
  let command = "git \{args.join(" ")}"
  let status = @process.run("git", args, cwd=project_dir) catch {
    err => raise @core.cli_error("failed to run `\{command}`: \{err}")
  }
  guard status == 0 else {
    raise @core.cli_error("`\{command}` failed with exit code \{status}")
  }
}
