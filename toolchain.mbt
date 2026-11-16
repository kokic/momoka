///|
async fn run_install_request(version : String) -> Unit raise @core.CliError {
  let status = install_toolchain(version) catch {
    err => raise @core.cli_error("failed to run the MoonBit installer: \{err}")
  }
  guard !(status == 0) else { return }
  raise @core.cli_error("MoonBit installation failed with exit code \{status}")
}

///|
async fn install_toolchain(version : String) -> Int32 raise Error {
  let extra_env = { "MOONBIT_INSTALL_VERSION": version }
  if @async.platform is Windows {
    @process.run(
      "powershell",
      [
        "-NoProfile", "-Command", "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex",
      ],
      extra_env~,
    )
  } else {
    @process.run(
      "bash",
      [
        "-o", "pipefail", "-c", "curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash",
      ],
      extra_env~,
    )
  }
}
