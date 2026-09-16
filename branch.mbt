///|
async fn run_branch_request() -> Unit raise CliError {
  let (status, output) = @process.collect_stdout("git", [
    "branch", "--format=%(refname:short)",
  ]) catch {
    err => raise CliError("failed to list Git branches: \{err}")
  }
  guard status == 0 else {
    raise CliError("git branch failed with exit code \{status}")
  }
  let content = output.text() catch {
    err => raise CliError("failed to decode Git branches: \{err}")
  }
  let branches = content
    .split("\n")
    .filter(line => !line.is_empty())
    .map(line => line.to_owned())
    .to_array()
  guard !branches.is_empty() else {
    raise CliError("no local Git branches available")
  }
  branches.eachi((index, name) => println("\{index + 1}. \{name}"))
  println("Enter branch number (1-\{branches.length()}):")
  guard read_line_from_stdin() is Some(line) else {
    raise CliError("failed to read branch number from stdin")
  }
  let number = @string.parse_int(line.trim()) catch {
    _ => raise CliError("invalid branch number")
  }
  guard number >= 1 && number <= branches.length() else {
    raise CliError("branch number must be between 1 and \{branches.length()}")
  }
  let status = @process.run("git", ["checkout", branches[number - 1], "--"]) catch {
    err => raise CliError("failed to check out Git branch: \{err}")
  }
  guard status == 0 else {
    raise CliError("git checkout failed with exit code \{status}")
  }
}
