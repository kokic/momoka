///|
async fn run_install_request(nightly~ : Bool) -> Unit raise CliError {
  let status = install_toolchain(nightly~) catch {
    err => raise CliError("failed to run the MoonBit installer: \{err}")
  }
  guard !(status == 0) else { return }
  raise CliError("MoonBit installation failed with exit code \{status}")
}

///|
#cfg(not(platform="windows"))
async fn install_toolchain(nightly~ : Bool) -> Int raise Error {
  // curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash -s 
  let edition = if nightly { " -s nightly" } else { "" }
  @process.run("bash", [
    "-o",
    "pipefail",
    "-c",
    "curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash\{edition}",
  ])
}

///|
#cfg(platform="windows")
async fn install_toolchain(nightly~ : Bool) -> Int raise Error {
  // Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; $env:MOONBIT_INSTALL_VERSION="nightly"; irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex
  let edition = {
    guard nightly else { "" }
    "$env:MOONBIT_INSTALL_VERSION=\"nightly\";"
  }
  @process.run("powershell", [
    "-NoProfile",
    "-Command",
    "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; \{edition} irm https://cli.moonbitlang.cn/install/powershell.ps1 | iex",
  ])
}
