///|
async fn run_evol_request(
  paths : ArrayView[String],
) -> Unit raise @core.CliError {
  let module_dirs = resolve_module_dirs(paths)
  if upgrade_modules(module_dirs) {
    bump_modules(module_dirs)
  } else {
    println("no dependency versions changed; skipped bump")
  }
  for module_dir in module_dirs {
    let status = @process.run("moon", ["check"], cwd=module_dir) catch {
      err => raise @core.cli_error("failed to run `moon check`: \{err}")
    }
    guard status == 0 else {
      raise @core.cli_error("`moon check` failed with exit code \{status}")
    }
  }
}
