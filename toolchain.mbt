///|
async fn run_install_request(nightly~ : Bool) -> Unit raise CliError {
  let status = install_toolchain(nightly~) catch {
    err => raise CliError("failed to run the MoonBit installer: \{err}")
  }
  guard status == 0 else {
    raise CliError("MoonBit installation failed with exit code \{status}")
  }
}

///|
async fn install_toolchain(nightly~ : Bool) -> Int raise Error {
  let args = if nightly { " -s nightly" } else { "" }
  @process.run("bash", [
    "-o",
    "pipefail",
    "-c",
    "curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash\{args}",
  ])
}

///|
#cfg(platform="windows")
async fn install_toolchain(nightly~ : Bool) -> Int raise Error {
  let version = if nightly {
    (
      #|$env:MOONBIT_INSTALL_VERSION="nightly";
    )
  } else {
    ""
  }
  @process.run("powershell", [
    "-NoProfile",
    "-Command",
    "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; \{version} irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex",
  ])
}
