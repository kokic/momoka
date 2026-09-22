///|
async fn run_branch_request() -> Unit raise @core.CliError {
  let (status, output) = @process.collect_stdout("git", [
    "branch", "--format=%(refname:short)",
  ]) catch {
    err => raise @core.cli_error("failed to list Git branches: \{err}")
  }
  guard status == 0 else {
    raise @core.cli_error("git branch failed with exit code \{status}")
  }
  let content = output.text() catch {
    err => raise @core.cli_error("failed to decode Git branches: \{err}")
  }
  let branches = content
    .split("\n")
    .filter(line => !line.is_empty())
    .map(line => line.to_owned())
    .to_array()
  guard !branches.is_empty() else {
    raise @core.cli_error("no local Git branches available")
  }
  branches.eachi((index, name) => println("\{index + 1}. \{name}"))
  println("Enter branch number (1-\{branches.length()}):")
  guard read_line_from_stdin() is Some(line) else {
    raise @core.cli_error("failed to read branch number from stdin")
  }
  let number = @string.parse_int(line.trim()) catch {
    _ => raise @core.cli_error("invalid branch number")
  }
  guard number >= 1 && number <= branches.length() else {
    raise @core.cli_error(
      "branch number must be between 1 and \{branches.length()}",
    )
  }
  let status = @process.run("git", ["checkout", branches[number - 1], "--"]) catch {
    err => raise @core.cli_error("failed to check out Git branch: \{err}")
  }
  guard status == 0 else {
    raise @core.cli_error("git checkout failed with exit code \{status}")
  }
}
