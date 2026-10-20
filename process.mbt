///|
async fn run_program(
  program : String,
  args : Array[String],
  cwd : String,
) -> Unit raise @core.CliError {
  let command = "\{program} \{args.join(" ")}"
  let status = @process.run(program, args, cwd~) catch {
    err => raise @core.cli_error("failed to run `\{command}`: \{err}")
  }
  guard status == 0 else {
    raise @core.cli_error("`\{command}` failed with exit code \{status}")
  }
}

///|
async fn run_git(
  project_dir : String,
  args : Array[String],
) -> Unit raise @core.CliError {
  run_program("git", args, project_dir)
}
